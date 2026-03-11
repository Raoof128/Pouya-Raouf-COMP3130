import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';

class AuthChangeEventNotifier extends Notifier<AuthChangeEvent?> {
  @override
  AuthChangeEvent? build() => null;

  void setEvent(AuthChangeEvent? event) {
    state = event;
  }
}

final lastAuthChangeEventProvider =
    NotifierProvider<AuthChangeEventNotifier, AuthChangeEvent?>(
      AuthChangeEventNotifier.new,
    );

/// Reactive auth state notifier backed by Supabase auth events.
class AuthNotifier extends AsyncNotifier<Session?> {
  StreamSubscription<AuthState>? _subscription;

  @override
  Future<Session?> build() async {
    final client = Supabase.instance.client;
    await _subscription?.cancel();
    _subscription = client.auth.onAuthStateChange.listen((data) {
      AppLogger.info('Auth event', data.event.name);
      ref.read(lastAuthChangeEventProvider.notifier).setEvent(data.event);
      state = AsyncData(data.session);
    });
    ref.onDispose(() => _subscription?.cancel());
    ref
        .read(lastAuthChangeEventProvider.notifier)
        .setEvent(AuthChangeEvent.initialSession);
    return client.auth.currentSession;
  }

  User? get currentUser => Supabase.instance.client.auth.currentUser;

  bool get isAuthenticated => state.value != null;

  bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  Future<bool> get isMfaVerified async {
    try {
      final aal = Supabase.instance.client.auth.mfa
          .getAuthenticatorAssuranceLevel();
      return aal.currentLevel == AuthenticatorAssuranceLevels.aal2;
    } catch (error, stackTrace) {
      AppLogger.warning('MFA assurance level check failed', error, stackTrace);
      return false;
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, Session?>(
  AuthNotifier.new,
);

final currentUserProvider = Provider<User?>((ref) {
  final session = ref.watch(authProvider).value;
  return session?.user;
});

class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
    ref.listen(lastAuthChangeEventProvider, (_, _) => notifyListeners());
  }
}
