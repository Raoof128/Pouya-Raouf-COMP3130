import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/app_router.dart';
import 'package:mq_navigation/app/theme/mq_theme.dart';
import 'package:mq_navigation/core/error/error_boundary.dart';
import 'package:mq_navigation/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';

class MqNavigationApp extends ConsumerWidget {
  const MqNavigationApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final preferences = ref.watch(settingsControllerProvider).value;
    ref.watch(notificationsControllerProvider);

    return MaterialApp.router(
      builder: (context, child) {
        ErrorWidget.builder = (details) {
          final error = buildFrameworkErrorFallback(details.exception);
          if (child is Scaffold || child is Navigator) {
            return Scaffold(body: Center(child: error));
          }
          return error;
        };
        return child ??
            buildFrameworkErrorFallback(
              StateError('Application shell failed to build.'),
            );
      },
      title: 'MQ Navigation',
      debugShowCheckedModeBanner: false,
      theme: MqTheme.light,
      darkTheme: MqTheme.dark,
      themeMode: preferences?.themeMode ?? ThemeMode.system,
      locale: preferences?.locale,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
