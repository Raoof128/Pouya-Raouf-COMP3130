import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mq_navigation/core/config/env_config.dart';

class PlaceSuggestion {
  const PlaceSuggestion({required this.placeId, required this.description});
  final String placeId;
  final String description;
}

final placesSearchSourceProvider = Provider((ref) => PlacesSearchSource());

/// Proxy client for Google Places Autocomplete.
///
/// Routes search queries through the Supabase `maps-places` Edge Function
/// to keep the Google Places API key safely on the server while enabling
/// global place fallback when a campus building search fails.
class PlacesSearchSource {
  Future<List<PlaceSuggestion>> search(
    String query, {
    double? latitude,
    double? longitude,
  }) async {
    if (query.trim().length < 2) return const [];

    final uri = Uri.parse('${EnvConfig.supabaseUrl}/functions/v1/maps-places');
    final body = <String, dynamic>{
      'query': query,
      'latitude': ?latitude,
      'longitude': ?longitude,
    };

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'apikey': EnvConfig.supabaseAnonKey,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final suggestions = data['suggestions'] as List<dynamic>? ?? [];

      return suggestions
          .map(
            (s) => PlaceSuggestion(
              placeId: s['placeId'] as String,
              description: s['description'] as String,
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
