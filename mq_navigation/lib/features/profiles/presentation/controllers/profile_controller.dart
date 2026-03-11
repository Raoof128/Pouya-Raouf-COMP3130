import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/features/profiles/data/repositories/profile_repository.dart';
import 'package:mq_navigation/shared/models/user_profile.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile?>(
      ProfileController.new,
    );

class ProfileController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() {
    return ref.read(profileRepositoryProvider).fetchCurrentProfile();
  }

  Future<String?> saveProfile(UserProfile profile) async {
    try {
      state = const AsyncLoading();
      final savedProfile = await ref
          .read(profileRepositoryProvider)
          .saveProfile(profile);
      state = AsyncData(savedProfile);
      return null;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to save profile through controller',
        error,
        stackTrace,
      );
      state = AsyncError(error, stackTrace);
      return 'Unable to save your profile.';
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(
      await ref.read(profileRepositoryProvider).fetchCurrentProfile(),
    );
  }
}
