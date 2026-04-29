import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/features/open_day/domain/entities/open_day_data.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';

/// Bundles the Open Day dataset asset path so it can be overridden in
/// tests without reaching into the loader implementation.
const _openDayAssetPath = 'assets/data/open_day.json';

/// Loads `assets/data/open_day.json` once per app session. The result is
/// cached by Riverpod so subsequent watchers don't re-parse the JSON.
///
/// Errors are surfaced via the standard `AsyncValue.error` channel so the
/// Open Day page can show a friendly retry state instead of crashing.
final openDayDataProvider = FutureProvider<OpenDayData>((ref) async {
  final raw = await rootBundle.loadString(_openDayAssetPath);
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return OpenDayData.fromJson(json);
});

/// Convenience: the currently selected bachelor object (or `null`).
///
/// Reads from settings + open-day data and joins them. Returning the
/// resolved `OpenDayBachelor` rather than just the id keeps every UI
/// consumer free of "look up the id again" boilerplate.
final selectedBachelorProvider = Provider<OpenDayBachelor?>((ref) {
  final selectedId = ref
      .watch(settingsControllerProvider)
      .value
      ?.selectedBachelorId;
  final data = ref.watch(openDayDataProvider).value;
  if (selectedId == null || data == null) return null;
  return data.bachelorById(selectedId);
});

/// Events relevant to the user's selected bachelor, sorted by start time.
///
/// When no bachelor is selected, returns events with empty `bachelorIds`
/// (treated as open to everyone) — keeps the page useful during onboarding.
final relevantOpenDayEventsProvider = Provider<List<OpenDayEvent>>((ref) {
  final data = ref.watch(openDayDataProvider).value;
  if (data == null) return const [];
  final selectedId = ref
      .watch(settingsControllerProvider)
      .value
      ?.selectedBachelorId;
  final filtered = data.events
      .where((e) => e.isRelevantTo(selectedId))
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  return filtered;
});
