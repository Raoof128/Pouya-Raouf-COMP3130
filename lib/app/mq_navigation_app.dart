import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/app_router.dart';
import 'package:mq_navigation/app/theme/mq_theme.dart';
import 'package:mq_navigation/core/error/error_boundary.dart';
import 'package:mq_navigation/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:mq_navigation/features/open_day/data/open_day_reminder_scheduler.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';

/// The root Flutter application widget.
///
/// Composes global app state including routing, theme, and localization.
/// Also observes the notifications controller so that push notification
/// setup side-effects execute immediately upon app startup.
class MqNavigationApp extends ConsumerStatefulWidget {
  const MqNavigationApp({super.key});

  @override
  ConsumerState<MqNavigationApp> createState() => _MqNavigationAppState();
}

class _MqNavigationAppState extends ConsumerState<MqNavigationApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _listenForDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _listenForDeepLinks() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null && mounted) {
      _handleDeepLink(initial);
    }
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (!mounted) {
        return;
      }
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.host != 'meet' || uri.scheme != 'io.mqnavigation') {
      return;
    }

    final lat = uri.queryParameters['lat'];
    final lng = uri.queryParameters['lng'];
    final router = ref.read(appRouterProvider);
    router.go('/meet?lat=$lat&lng=$lng');
  }

  @override
  Widget build(BuildContext context) {
    // Watch global navigation state.
    final router = ref.watch(appRouterProvider);

    // Watch global preferences (theme, locale) loaded from local storage.
    final preferences = ref.watch(settingsControllerProvider).value;

    // Explicitly watch the notifications controller to keep it alive.
    // This triggers FCM permission requests and token sync side effects
    // independently of whether the user is on the notifications page.
    ref.watch(notificationsControllerProvider);

    // Keep the Open Day reminder scheduler alive for the app lifetime.
    // The scheduler installs Riverpod listeners on bachelor selection,
    // notification toggles, and lead time — so reminders rebuild
    // automatically whenever the user changes any of those.
    ref.watch(openDayReminderSchedulerProvider);

    return MaterialApp.router(
      // The builder is used to wrap the entire app with a custom error widget.
      // If a widget fails to build, this prevents the grey "red screen of death"
      // and shows a friendlier fallback UI instead.
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
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
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
