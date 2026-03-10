import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/app_router.dart';
import 'package:mq_navigation/app/theme/mq_theme.dart';

/// Root application widget.
class MqNavigationApp extends ConsumerWidget {
  const MqNavigationApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'MQ Navigation',
      debugShowCheckedModeBanner: false,
      theme: MqTheme.light,
      darkTheme: MqTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Override the default red error screen with a user-friendly widget,
      // as recommended by Flutter's error handling docs.
      builder: (context, widget) {
        ErrorWidget.builder = (details) => _buildErrorWidget(context, details);
        if (widget != null) return widget;
        throw StateError('MaterialApp.router returned null widget');
      },
    );
  }

  /// Builds a user-friendly error widget shown when an individual widget
  /// fails to build, instead of the default red/grey error screen.
  static Widget _buildErrorWidget(
    BuildContext context,
    FlutterErrorDetails details,
  ) {
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'A rendering error occurred.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

