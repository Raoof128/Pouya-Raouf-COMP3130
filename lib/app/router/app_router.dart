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
///
/// **Why we use `.select()` instead of `ref.watch(settingsControllerProvider)`:**
/// The redirect callback only depends on two pieces of settings state —
/// the loading flag and `hasCompletedOnboarding`. If we watched the entire
/// settings AsyncValue, *every* preference change (theme, locale, bachelor,
/// commute mode, …) would invalidate this provider. That recreates the
/// whole `GoRouter`, which in turn makes Flutter rebuild the active
/// MaterialPage and replay its entry transition — i.e. a full-screen
/// slide on every preference toggle. Scoping the dependency with
/// `.select()` keeps preference changes silent at the router level so
/// only true navigation triggers transitions.
final appRouterProvider = Provider<GoRouter>((ref) {
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

      // Read latest settings inside the redirect — this does NOT subscribe
      // the provider to settings changes; it only reads the current value.
      final settingsAsync = ref.read(settingsControllerProvider);

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
    // Re-run the redirect whenever the onboarding-completion bit flips.
    // This is the only piece of settings state the redirect cares about,
    // so we listen to *just* that bit. Other preference changes (theme,
    // locale, bachelor, …) no longer trigger router rebuilds.
    refreshListenable: _OnboardingFlagListenable(ref),
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

/// Tiny [Listenable] adapter for `GoRouter.refreshListenable`.
///
/// The redirect cares about exactly two pieces of settings state:
///   1. `s.isLoading`  — while loading we don't redirect at all
///   2. `s.value?.hasCompletedOnboarding` — drives the onboarding gate
///
/// We listen to a record of *both* projected via `.select()` so the
/// listener fires when EITHER changes:
///   - first launch: `(loading=true, _)` → `(loading=false, false)` →
///     redirect re-runs and bounces to `/onboarding`. (Without listening
///     to `isLoading`, the projected onboarding bool would stay `false`
///     across the loading→data transition and the redirect would never
///     fire — the user would land on `/home` instead of `/onboarding`.)
///   - completion: `hasCompleted` flips `false → true`, redirect re-runs
///     and stops bouncing back.
///
/// Records use value-equality, so unrelated settings changes (theme,
/// locale, bachelor, …) keep this listener silent and the router stable.
class _OnboardingFlagListenable extends ChangeNotifier {
  _OnboardingFlagListenable(Ref ref) {
    _sub = ref.listen<({bool isLoading, bool hasCompleted})>(
      settingsControllerProvider.select(
        (s) => (
          isLoading: s.isLoading,
          hasCompleted: s.value?.hasCompletedOnboarding ?? false,
        ),
      ),
      (_, _) => notifyListeners(),
      fireImmediately: false,
    );
    ref.onDispose(() => _sub?.close());
  }

  ProviderSubscription<({bool isLoading, bool hasCompleted})>? _sub;
}
