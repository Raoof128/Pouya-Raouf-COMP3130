import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';

@immutable
class PendingTotpEnrollment {
  const PendingTotpEnrollment({
    required this.factorId,
    required this.qrCode,
    required this.secret,
    required this.uri,
  });

  final String factorId;
  final String qrCode;
  final String secret;
  final String uri;
}

@immutable
class MfaState {
  const MfaState({
    required this.factors,
    required this.currentLevel,
    required this.nextLevel,
    this.pendingEnrollment,
  });

  final List<Factor> factors;
  final AuthenticatorAssuranceLevels? currentLevel;
  final AuthenticatorAssuranceLevels? nextLevel;
  final PendingTotpEnrollment? pendingEnrollment;

  bool get hasVerifiedFactor =>
      factors.any((factor) => factor.status == FactorStatus.verified);

  Factor? get primaryVerifiedFactor {
    for (final factor in factors) {
      if (factor.status == FactorStatus.verified) {
        return factor;
      }
    }
    return null;
  }

  MfaState copyWith({
    List<Factor>? factors,
    AuthenticatorAssuranceLevels? currentLevel,
    AuthenticatorAssuranceLevels? nextLevel,
    PendingTotpEnrollment? pendingEnrollment,
    bool clearPendingEnrollment = false,
  }) {
    return MfaState(
      factors: factors ?? this.factors,
      currentLevel: currentLevel ?? this.currentLevel,
      nextLevel: nextLevel ?? this.nextLevel,
      pendingEnrollment: clearPendingEnrollment
          ? null
          : pendingEnrollment ?? this.pendingEnrollment,
    );
  }
}

final mfaControllerProvider = AsyncNotifierProvider<MfaController, MfaState>(
  MfaController.new,
);

class MfaController extends AsyncNotifier<MfaState> {
  @override
  Future<MfaState> build() => _loadState();

  Future<String?> refresh() async {
    try {
      state = const AsyncLoading();
      state = AsyncData(await _loadState());
      return null;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to refresh MFA state', error, stackTrace);
      state = AsyncError(error, stackTrace);
      return 'Unable to refresh MFA status.';
    }
  }

  Future<String?> enrollTotp() async {
    final currentState = state.value;
    state = const AsyncLoading();
    try {
      final response = await Supabase.instance.client.auth.mfa.enroll(
        issuer: 'MQ Navigation',
        friendlyName: 'Mobile app',
      );
      final loaded = await _loadState();
      state = AsyncData(
        loaded.copyWith(
          pendingEnrollment: PendingTotpEnrollment(
            factorId: response.id,
            qrCode: response.totp?.qrCode ?? '',
            secret: response.totp?.secret ?? '',
            uri: response.totp?.uri ?? '',
          ),
        ),
      );
      return null;
    } on AuthException catch (error, stackTrace) {
      AppLogger.warning('Failed to enroll MFA factor', error, stackTrace);
      state = AsyncData(currentState ?? await _loadState());
      return error.message;
    } catch (error, stackTrace) {
      AppLogger.error('Unexpected MFA enrollment error', error, stackTrace);
      state = AsyncData(currentState ?? await _loadState());
      return 'Unable to start MFA enrollment.';
    }
  }

  Future<String?> verifyPendingEnrollment(String code) async {
    final pendingEnrollment = state.value?.pendingEnrollment;
    if (pendingEnrollment == null) {
      return 'Start enrollment before verifying a code.';
    }

    state = const AsyncLoading();
    try {
      await Supabase.instance.client.auth.mfa.challengeAndVerify(
        factorId: pendingEnrollment.factorId,
        code: code.trim(),
      );
      state = AsyncData(await _loadState());
      return null;
    } on AuthException catch (error, stackTrace) {
      AppLogger.warning('Failed to verify MFA enrollment', error, stackTrace);
      state = AsyncData(
        (await _loadState()).copyWith(pendingEnrollment: pendingEnrollment),
      );
      return error.message;
    } catch (error, stackTrace) {
      AppLogger.error('Unexpected MFA verification error', error, stackTrace);
      state = AsyncData(
        (await _loadState()).copyWith(pendingEnrollment: pendingEnrollment),
      );
      return 'Unable to verify MFA code.';
    }
  }

  Future<String?> verifyExistingFactor(String code) async {
    final factor = state.value?.primaryVerifiedFactor;
    if (factor == null) {
      return 'Set up multi-factor authentication first.';
    }

    state = const AsyncLoading();
    try {
      await Supabase.instance.client.auth.mfa.challengeAndVerify(
        factorId: factor.id,
        code: code.trim(),
      );
      state = AsyncData(await _loadState());
      return null;
    } on AuthException catch (error, stackTrace) {
      AppLogger.warning('Failed MFA challenge', error, stackTrace);
      state = AsyncData(await _loadState());
      return error.message;
    } catch (error, stackTrace) {
      AppLogger.error('Unexpected MFA challenge error', error, stackTrace);
      state = AsyncData(await _loadState());
      return 'Unable to verify MFA code.';
    }
  }

  Future<String?> unenroll(String factorId) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.auth.mfa.unenroll(factorId);
      state = AsyncData(await _loadState());
      return null;
    } on AuthException catch (error, stackTrace) {
      AppLogger.warning('Failed to unenroll MFA factor', error, stackTrace);
      state = AsyncData(await _loadState());
      return error.message;
    } catch (error, stackTrace) {
      AppLogger.error('Unexpected MFA unenroll error', error, stackTrace);
      state = AsyncData(await _loadState());
      return 'Unable to remove MFA right now.';
    }
  }

  Future<MfaState> _loadState() async {
    final listFactorsResponse = await Supabase.instance.client.auth.mfa
        .listFactors();
    final aal = Supabase.instance.client.auth.mfa
        .getAuthenticatorAssuranceLevel();
    return MfaState(
      factors: listFactorsResponse.all,
      currentLevel: aal.currentLevel,
      nextLevel: aal.nextLevel,
    );
  }
}
