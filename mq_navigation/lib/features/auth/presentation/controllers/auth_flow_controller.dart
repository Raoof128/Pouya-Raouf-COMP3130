import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/error/app_exception.dart' as app_exception;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/auth/data/repositories/auth_repository.dart';

final authActionControllerProvider =
    AsyncNotifierProvider<AuthActionController, void>(AuthActionController.new);

class AuthActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    return _runGuarded(() async {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email.trim(), password: password);
    });
  }

  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    return _runGuarded(() async {
      await ref
          .read(authRepositoryProvider)
          .signUp(email: email.trim(), password: password);
    });
  }

  Future<String?> signInWithGoogle() async {
    return _runGuarded(() async {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    });
  }

  Future<String?> sendPasswordReset(String email) async {
    return _runGuarded(() async {
      await ref.read(authRepositoryProvider).sendPasswordReset(email.trim());
    });
  }

  Future<String?> updatePassword(String newPassword) async {
    return _runGuarded(() async {
      await ref.read(authRepositoryProvider).updatePassword(newPassword);
    });
  }

  Future<String?> resendVerification(String email) async {
    return _runGuarded(() async {
      await ref.read(authRepositoryProvider).resendVerification(email.trim());
    });
  }

  Future<String?> signOut() async {
    return _runGuarded(() async {
      await ref.read(authRepositoryProvider).signOut();
    });
  }

  Future<String?> _runGuarded(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = const AsyncData(null);
      return null;
    } on app_exception.AppException catch (error, stackTrace) {
      AppLogger.warning('App auth flow failed', error, stackTrace);
      state = AsyncError(error, stackTrace);
      return error.message;
    } on AuthException catch (error, stackTrace) {
      AppLogger.warning('Auth flow failed', error, stackTrace);
      state = AsyncError(error, stackTrace);
      return error.message;
    } catch (error, stackTrace) {
      AppLogger.error('Unexpected auth flow error', error, stackTrace);
      state = AsyncError(error, stackTrace);
      return 'Something went wrong. Please try again.';
    }
  }
}
