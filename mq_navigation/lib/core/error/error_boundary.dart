import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';

/// App-level wrapper kept for API stability.
///
/// Flutter does not support React-style widget error boundaries that recover by
/// calling `setState` from `FlutterError.onError`. Framework build/layout/paint
/// failures are instead surfaced through [ErrorWidget.builder], which is
/// configured from the app shell. This widget simply passes its child through.
class ErrorBoundary extends StatelessWidget {
  const ErrorBoundary({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _ErrorFallback extends StatelessWidget {
  const _ErrorFallback({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFF5F5F5),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD0D0D0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Application error',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Something went wrong while building the UI.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildFrameworkErrorFallback(Object error) {
  return _ErrorFallback(error: error);
}

/// Installs global error handlers as recommended by Flutter's error handling
/// documentation (https://docs.flutter.dev/testing/errors).
///
/// Sets up two global logging layers:
/// 1. [FlutterError.onError] — catches errors during widget build/layout/paint
/// 2. [PlatformDispatcher.instance.onError] — catches platform-level errors
///    (unhandled Future errors, isolate errors) that escape the Flutter framework
/// 3. [runZonedGuarded] — set up separately in bootstrap.dart as a final fallback
void installErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Flutter framework error',
      details.exception,
      details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Platform dispatcher error', error, stack);
    return true;
  };
}
