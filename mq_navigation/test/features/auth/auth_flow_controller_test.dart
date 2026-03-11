import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/core/error/app_exception.dart' as app_exception;
import 'package:mq_navigation/features/auth/data/repositories/auth_repository.dart';
import 'package:mq_navigation/features/auth/presentation/controllers/auth_flow_controller.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.errorToThrow, this.googleLaunchResult = true});

  final Object? errorToThrow;
  final bool googleLaunchResult;
  int signInCalls = 0;

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signInWithGoogle() async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    if (!googleLaunchResult) {
      throw const app_exception.UnsupportedException(
        'Unable to open the Google sign-in flow on this device.',
      );
    }
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls += 1;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return AuthResponse();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return AuthResponse();
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    throw UnimplementedError();
  }

  @override
  Future<ResendResponse> resendVerification(String email) async {
    throw UnimplementedError();
  }
}

void main() {
  group('AuthActionController', () {
    test('returns null on successful sign in', () async {
      final fakeRepository = _FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authActionControllerProvider.notifier);
      final message = await notifier.signIn(
        email: 'student@example.com',
        password: 'supersecure',
      );

      expect(message, isNull);
      expect(fakeRepository.signInCalls, 1);
      expect(container.read(authActionControllerProvider).hasError, isFalse);
    });

    test('surfaces supabase auth exception messages', () async {
      final fakeRepository = _FakeAuthRepository(
        errorToThrow: const AuthException('Invalid credentials'),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authActionControllerProvider.notifier);
      final message = await notifier.signIn(
        email: 'student@example.com',
        password: 'wrong',
      );

      expect(message, 'Invalid credentials');
      expect(container.read(authActionControllerProvider).hasError, isTrue);
    });

    test('surfaces Google OAuth launch failures', () async {
      final fakeRepository = _FakeAuthRepository(googleLaunchResult: false);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authActionControllerProvider.notifier);
      final message = await notifier.signInWithGoogle();

      expect(message, 'Unable to open the Google sign-in flow on this device.');
      expect(container.read(authActionControllerProvider).hasError, isTrue);
    });
  });
}
