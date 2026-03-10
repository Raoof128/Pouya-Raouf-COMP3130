import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/core/config/env_config.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';

/// Reactive auth state notifier backed by Supabase auth events.
///
/// Emits `AsyncData<Session?>` — a non-null [Session] when authenticated,
/// `null` when signed out, and `AsyncLoading` during initial resolution.
/// Returns `null` immediately in demo mode (no Supabase credentials).
class AuthNotifier extends AsyncNotifier<Session?> {
  StreamSubscription<AuthState>? _sub;

  @override
  Future<Session?> build() async {
    // Demo mode: no Supabase, so no session.
    if (!EnvConfig.hasSupabase) return null;

    final client = Supabase.instance.client;
    unawaited(_sub?.cancel());
    _sub = client.auth.onAuthStateChange.listen((data) {
      AppLogger.info('Auth event', data.event.name);
      state = AsyncData(data.session);
    });
    ref.onDispose(() => _sub?.cancel());
    return client.auth.currentSession;
  }

  User? get currentUser =>
      EnvConfig.hasSupabase ? Supabase.instance.client.auth.currentUser : null;

  bool get isAuthenticated => state.value != null;

  /// Check if email is verified.
  bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  /// Check if MFA is enrolled (AAL2).
  Future<bool> get isMfaVerified async {
    try {
      final aal = Supabase.instance.client.auth.mfa
          .getAuthenticatorAssuranceLevel();
      return aal.currentLevel == AuthenticatorAssuranceLevels.aal2;
    } catch (e, s) {
      AppLogger.warning('MFA assurance level check failed', e, s);
      return false;
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}

/// The primary auth state provider.
///
/// Returns `AsyncLoading` during initial session resolution, then
/// `AsyncData<Session?>` — non-null when authenticated, `null` when signed out.
/// All route guards and feature screens should depend on this provider.
final authProvider = AsyncNotifierProvider<AuthNotifier, Session?>(
  AuthNotifier.new,
);

/// Convenience provider: the currently signed-in [User], or `null`.
final currentUserProvider = Provider<User?>((ref) {
  final session = ref.watch(authProvider).value;
  return session?.user;
});

/// A [ChangeNotifier] that fires whenever [authProvider] changes,
/// allowing [GoRouter.refreshListenable] to re-evaluate redirects
/// without rebuilding the entire router.
class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
  }
}
