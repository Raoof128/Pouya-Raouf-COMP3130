String? resolveRouteRedirect({
  required String currentPath,
  required bool isLoading,
  required bool isAuthenticated,
  required bool isEmailVerified,
  required bool requiresMfa,
  required bool needsOnboarding,
  required bool isInPasswordRecovery,
}) {
  const authPaths = <String>{
    '/login',
    '/signup',
    '/reset-password',
    '/verify-email',
  };
  const transitionalPaths = <String>{
    '/splash',
    '/verify-email',
    '/onboarding',
    '/mfa',
  };

  if (isLoading) {
    return currentPath == '/splash' ? null : '/splash';
  }

  if (isInPasswordRecovery && currentPath != '/reset-password') {
    return '/reset-password?mode=recovery';
  }

  if (!isAuthenticated) {
    if (authPaths.contains(currentPath)) {
      return null;
    }
    return '/login';
  }

  if (!isEmailVerified) {
    return currentPath == '/verify-email' ? null : '/verify-email';
  }

  if (requiresMfa) {
    return currentPath == '/mfa' ? null : '/mfa';
  }

  if (needsOnboarding) {
    return currentPath == '/onboarding' ? null : '/onboarding';
  }

  if (authPaths.contains(currentPath) ||
      transitionalPaths.contains(currentPath)) {
    return '/home';
  }

  return null;
}
