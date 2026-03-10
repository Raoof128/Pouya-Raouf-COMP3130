import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/router/app_shell.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/features/auth/presentation/pages/splash_page.dart';
import 'package:mq_navigation/features/home/presentation/pages/home_page.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/presentation/pages/building_detail_page.dart';
import 'package:mq_navigation/features/map/presentation/pages/directions_page.dart';
import 'package:mq_navigation/features/map/presentation/pages/map_page.dart';
import 'package:mq_navigation/features/settings/presentation/pages/settings_page.dart';
import 'package:mq_navigation/shared/providers/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Application router with guest-mode navigation for Open Day.
///
/// Uses [AuthRefreshNotifier] as a `refreshListenable` so the single
/// [GoRouter] instance re-evaluates redirects on auth state changes
/// without being rebuilt.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: EnvConfig.isDevelopment,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final currentPath = state.matchedLocation;

      // While auth is loading, stay on splash.
      if (authState.isLoading) {
        return currentPath == '/splash' ? null : '/splash';
      }

      // Once loaded, leave splash for home.
      if (currentPath == '/splash') return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),

      // -- Main Shell (bottom nav): Home, Map, Settings --
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
                builder: (context, state) => const MapPage(),
                routes: [
                  GoRoute(
                    path: 'building',
                    name: RouteNames.buildingDetail,
                    builder: (context, state) {
                      final building = state.extra! as Building;
                      return BuildingDetailPage(building: building);
                    },
                  ),
                  GoRoute(
                    path: 'directions',
                    name: RouteNames.directions,
                    builder: (context, state) {
                      final building = state.extra! as Building;
                      return DirectionsPage(destination: building);
                    },
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
