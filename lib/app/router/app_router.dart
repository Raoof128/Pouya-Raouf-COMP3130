import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/router/app_shell.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/features/deep_link/deep_link_contract.dart';
import 'package:mq_navigation/features/home/presentation/pages/home_page.dart';
import 'package:mq_navigation/features/home/presentation/pages/onboarding_page.dart';
import 'package:mq_navigation/features/map/presentation/pages/map_page.dart';
import 'package:mq_navigation/features/notifications/presentation/pages/notifications_page.dart';
import 'package:mq_navigation/features/open_day/presentation/pages/open_day_page.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_navigation/features/settings/presentation/pages/settings_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Central GoRouter configuration for the app.
/// Uses a stateful shell so each bottom-tab branch keeps its own
/// navigation stack instead of resetting when the user switches tabs.
final appRouterProvider = Provider<GoRouter>((ref) {
  final settingsAsync = ref.watch(settingsControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    debugLogDiagnostics: EnvConfig.isDevelopment,
    redirect: (context, state) {
      final isOnboardingRoute = state.uri.path == '/onboarding';

      // If already on onboarding or settings are loading, don't redirect
      if (isOnboardingRoute) {
        return null;
      }

      // If settings haven't loaded yet, don't redirect - let them load first
      if (settingsAsync.isLoading) {
        return null;
      }

      final hasCompleted = settingsAsync.value?.hasCompletedOnboarding ?? false;

      if (!hasCompleted) {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      // Syllabus Sync integration entry point.
      //
      // Stable, versioned public URL — see deep_link_contract.dart for the
      // supported payload shape. Internal routes may change; this one may
      // NOT change without a compatibility plan for Syllabus Sync clients.
      GoRoute(
        path: '/open',
        redirect: (context, state) {
          final target = parseMqNavDeepLink(state.uri.queryParameters);
          return switch (target) {
            DeepLinkBuilding(:final buildingId) =>
              '/map/building/${Uri.encodeComponent(buildingId)}',
            DeepLinkSearch(:final query) =>
              '/map?q=${Uri.encodeQueryComponent(query)}',
            DeepLinkMeetAt(:final latitude, :final longitude) =>
              '/meet?lat=$latitude&lng=$longitude',
            DeepLinkFallback() => '/map',
          };
        },
      ),
      // Notifications sits outside the shell so it covers the bottom nav bar.
      GoRoute(
        path: '/meet',
        name: RouteNames.meet,
        builder: (context, state) {
          final lat = double.tryParse(state.uri.queryParameters['lat'] ?? '');
          final lng = double.tryParse(state.uri.queryParameters['lng'] ?? '');
          return MapPage(meetLat: lat, meetLng: lng);
        },
      ),
      GoRoute(
        path: '/notifications',
        name: RouteNames.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      // Open Day — dedicated screen, deliberately *outside* the bottom-nav
      // shell so it doesn't permanently consume one of the three tabs.
      // Open Day is a temporal feature; pushing it here keeps the nav
      // surface stable post-Open-Day.
      GoRoute(
        path: '/open-day',
        name: RouteNames.openDay,
        builder: (context, state) => const OpenDayPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      // The shell route handles the bottom navigation bar and nested routing.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                name: RouteNames.map,
                builder: (context, state) =>
                    MapPage(initialSearchQuery: state.uri.queryParameters['q']),
                routes: [
                  GoRoute(
                    path: 'building/:buildingId',
                    name: RouteNames.buildingDetail,
                    builder: (context, state) => MapPage(
                      initialBuildingId: state.pathParameters['buildingId'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: RouteNames.settings,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
