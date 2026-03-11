import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/app/router/route_guard.dart';

void main() {
  group('resolveRouteRedirect', () {
    test('keeps splash while auth is loading', () {
      expect(
        resolveRouteRedirect(
          currentPath: '/splash',
          isLoading: true,
          isAuthenticated: false,
          isEmailVerified: false,
          requiresMfa: false,
          needsOnboarding: false,
          isInPasswordRecovery: false,
        ),
        isNull,
      );
    });

    test('redirects anonymous users to login for protected routes', () {
      expect(
        resolveRouteRedirect(
          currentPath: '/home',
          isLoading: false,
          isAuthenticated: false,
          isEmailVerified: false,
          requiresMfa: false,
          needsOnboarding: false,
          isInPasswordRecovery: false,
        ),
        '/login',
      );
    });

    test(
      'redirects anonymous users away from splash once loading finishes',
      () {
        expect(
          resolveRouteRedirect(
            currentPath: '/splash',
            isLoading: false,
            isAuthenticated: false,
            isEmailVerified: false,
            requiresMfa: false,
            needsOnboarding: false,
            isInPasswordRecovery: false,
          ),
          '/login',
        );
      },
    );

    test('redirects password recovery sessions to reset route', () {
      expect(
        resolveRouteRedirect(
          currentPath: '/home',
          isLoading: false,
          isAuthenticated: true,
          isEmailVerified: true,
          requiresMfa: false,
          needsOnboarding: false,
          isInPasswordRecovery: true,
        ),
        '/reset-password?mode=recovery',
      );
    });

    test('redirects unverified users to email verification', () {
      expect(
        resolveRouteRedirect(
          currentPath: '/home',
          isLoading: false,
          isAuthenticated: true,
          isEmailVerified: false,
          requiresMfa: false,
          needsOnboarding: false,
          isInPasswordRecovery: false,
        ),
        '/verify-email',
      );
    });

    test('redirects enrolled users to mfa when aal is insufficient', () {
      expect(
        resolveRouteRedirect(
          currentPath: '/home',
          isLoading: false,
          isAuthenticated: true,
          isEmailVerified: true,
          requiresMfa: true,
          needsOnboarding: false,
          isInPasswordRecovery: false,
        ),
        '/mfa',
      );
    });

    test('redirects incomplete users to onboarding after auth checks pass', () {
      expect(
        resolveRouteRedirect(
          currentPath: '/home',
          isLoading: false,
          isAuthenticated: true,
          isEmailVerified: true,
          requiresMfa: false,
          needsOnboarding: true,
          isInPasswordRecovery: false,
        ),
        '/onboarding',
      );
    });

    test('redirects authenticated users away from auth routes to home', () {
      expect(
        resolveRouteRedirect(
          currentPath: '/login',
          isLoading: false,
          isAuthenticated: true,
          isEmailVerified: true,
          requiresMfa: false,
          needsOnboarding: false,
          isInPasswordRecovery: false,
        ),
        '/home',
      );
    });
  });
}
