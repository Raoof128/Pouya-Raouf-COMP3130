import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/core/error/app_exception.dart';
import 'package:mq_navigation/core/logging/app_logger.dart';
import 'package:mq_navigation/shared/models/user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile?> fetchCurrentProfile();
  Future<UserProfile> saveProfile(UserProfile profile);
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(Supabase.instance.client);
});

class SupabaseProfileRepository implements ProfileRepository {
  const SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<UserProfile?> fetchCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        return UserProfile(id: user.id, email: user.email ?? '');
      }

      final profile = UserProfile.fromJson(Map<String, dynamic>.from(response));
      if (profile.email.isEmpty && user.email != null) {
        return profile.copyWith(email: user.email);
      }
      return profile;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to fetch profile', error, stackTrace);
      throw ServerException('Unable to load your profile.', cause: error);
    }
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    try {
      final response = await _client
          .from('profiles')
          .upsert(profile.toUpsertJson(), onConflict: 'id')
          .select()
          .single();

      return UserProfile.fromJson(Map<String, dynamic>.from(response));
    } catch (error, stackTrace) {
      AppLogger.error('Failed to save profile', error, stackTrace);
      throw ServerException('Unable to save your profile.', cause: error);
    }
  }
}
