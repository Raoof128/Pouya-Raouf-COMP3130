import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';

/// Widget that catches uncaught errors in its subtree and shows a fallback UI.
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({super.key, required this.child});

  final Widget child;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  void Function(FlutterErrorDetails)? _previousHandler;

  @override
  void initState() {
    super.initState();
    _previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      AppLogger.error(
        'ErrorBoundary caught Flutter error',
        details.exception,
        details.stack,
      );
      if (mounted) {
        setState(() => _error = details.exception);
      }
    };
  }

  @override
  void dispose() {
    FlutterError.onError = _previousHandler;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorFallback(
        error: _error!,
        onRetry: () => setState(() => _error = null),
      );
    }
    return widget.child;
  }
}

class _ErrorFallback extends StatelessWidget {
  const _ErrorFallback({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Installs global error handlers as recommended by Flutter's error handling
/// documentation (https://docs.flutter.dev/testing/errors).
///
/// Sets up three layers:
/// 1. [FlutterError.onError] — catches errors during widget build/layout/paint
/// 2. [PlatformDispatcher.instance.onError] — catches platform-level errors
///    (unhandled Future errors, isolate errors) that escape the Flutter framework
/// 3. [runZonedGuarded] — set up separately in bootstrap.dart as a final fallback
void installErrorHandlers() {
  // Custom error widget for release mode.
  ErrorWidget.builder = (details) {
    return const Material(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'A rendering error occurred.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  // Layer 1: Flutter framework errors (widget build, layout, paint).
  FlutterError.onError = (details) {
    // Preserve default debug console output.
    FlutterError.presentError(details);
    AppLogger.error(
      'Flutter framework error',
      details.exception,
      details.stack,
    );
  };

  // Layer 2: Platform-level errors (unhandled Futures, isolate errors).
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Platform dispatcher error', error, stack);
    return true; // Prevents the error from being reported to the zone.
  };
}
