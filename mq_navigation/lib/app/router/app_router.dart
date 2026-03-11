import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/app/router/app_shell.dart';
import 'package:mq_navigation/app/router/route_guard.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/auth/presentation/pages/login_page.dart';
import 'package:mq_navigation/features/auth/presentation/pages/mfa_page.dart';
import 'package:mq_navigation/features/auth/presentation/pages/reset_password_page.dart';
import 'package:mq_navigation/features/auth/presentation/pages/signup_page.dart';
import 'package:mq_navigation/features/auth/presentation/pages/splash_page.dart';
import 'package:mq_navigation/features/auth/presentation/pages/verify_email_page.dart';
import 'package:mq_navigation/features/calendar/presentation/pages/calendar_page.dart';
import 'package:mq_navigation/features/calendar/presentation/pages/academic_item_detail_page.dart';
import 'package:mq_navigation/features/feed/presentation/pages/feed_page.dart';
import 'package:mq_navigation/features/home/presentation/pages/home_page.dart';
import 'package:mq_navigation/features/map/presentation/pages/map_page.dart';
import 'package:mq_navigation/features/notifications/presentation/pages/notifications_page.dart';
import 'package:mq_navigation/features/profiles/data/repositories/profile_repository.dart';
import 'package:mq_navigation/features/profiles/presentation/pages/profile_edit_page.dart';
import 'package:mq_navigation/features/settings/presentation/pages/settings_page.dart';
import 'package:mq_navigation/shared/providers/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: EnvConfig.isDevelopment,
    refreshListenable: refreshNotifier,
    redirect: (context, state) async {
      final authState = ref.read(authProvider);
      final currentPath = state.matchedLocation;

      if (authState.isLoading) {
        return resolveRouteRedirect(
          currentPath: currentPath,
          isLoading: true,
          isAuthenticated: false,
          isEmailVerified: false,
          requiresMfa: false,
          needsOnboarding: false,
          isInPasswordRecovery: false,
        );
      }

      final session = authState.value;
      final isAuthenticated = session != null;
      var isEmailVerified = false;
      var requiresMfa = false;
      var needsOnboarding = false;

      if (session != null) {
        isEmailVerified = session.user.emailConfirmedAt != null;

        if (isEmailVerified) {
          try {
            final factors = await Supabase.instance.client.auth.mfa
                .listFactors();
            final aal = Supabase.instance.client.auth.mfa
                .getAuthenticatorAssuranceLevel();
            requiresMfa =
                factors.all.any(
                  (factor) => factor.status == FactorStatus.verified,
                ) &&
                aal.currentLevel != AuthenticatorAssuranceLevels.aal2;
          } catch (error, stackTrace) {
            AppLogger.warning(
              'Failed to evaluate MFA guard state',
              error,
              stackTrace,
            );
          }

          if (!requiresMfa) {
            try {
              final profile = await ref
                  .read(profileRepositoryProvider)
                  .fetchCurrentProfile();
              needsOnboarding = profile == null || !profile.isComplete;
            } catch (error, stackTrace) {
              AppLogger.warning(
                'Failed to evaluate onboarding guard state',
                error,
                stackTrace,
              );
            }
          }
        }
      }

      final lastEvent = ref.read(lastAuthChangeEventProvider);
      final isInPasswordRecovery =
          lastEvent == AuthChangeEvent.passwordRecovery;

      return resolveRouteRedirect(
        currentPath: currentPath,
        isLoading: false,
        isAuthenticated: isAuthenticated,
        isEmailVerified: isEmailVerified,
        requiresMfa: requiresMfa,
        needsOnboarding: needsOnboarding,
        isInPasswordRecovery: isInPasswordRecovery,
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        name: RouteNames.signup,
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/verify-email',
        name: RouteNames.verifyEmail,
        builder: (context, state) =>
            VerifyEmailPage(email: state.uri.queryParameters['email']),
      ),
      GoRoute(
        path: '/reset-password',
        name: RouteNames.resetPassword,
        builder: (context, state) => ResetPasswordPage(
          forceRecoveryMode: state.uri.queryParameters['mode'] == 'recovery',
        ),
      ),
      GoRoute(
        path: '/mfa',
        name: RouteNames.mfa,
        builder: (context, state) => const MfaPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, state) => const ProfileEditPage(isOnboarding: true),
      ),
      GoRoute(
        path: '/profile/edit',
        name: RouteNames.profileEdit,
        builder: (context, state) => const ProfileEditPage(),
      ),
      GoRoute(
        path: '/notifications',
        name: RouteNames.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/detail/deadline/:deadlineId',
        name: RouteNames.deadlineDetail,
        builder: (context, state) => AcademicItemDetailPage(
          itemId: state.pathParameters['deadlineId']!,
          detailType: AcademicItemDetailType.deadline,
        ),
      ),
      GoRoute(
        path: '/detail/exam/:examId',
        name: RouteNames.examDetail,
        builder: (context, state) => AcademicItemDetailPage(
          itemId: state.pathParameters['examId']!,
          detailType: AcademicItemDetailType.exam,
        ),
      ),
      GoRoute(
        path: '/detail/event/:eventId',
        name: RouteNames.eventDetail,
        builder: (context, state) => AcademicItemDetailPage(
          itemId: state.pathParameters['eventId']!,
          detailType: AcademicItemDetailType.event,
        ),
      ),
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
                path: '/calendar',
                name: RouteNames.calendar,
                builder: (context, state) => const CalendarPage(),
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
                path: '/feed',
                name: RouteNames.feed,
                builder: (context, state) => const FeedPage(),
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
