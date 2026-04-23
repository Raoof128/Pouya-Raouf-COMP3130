import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_animations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/core/utils/haptics.dart';
import 'package:mq_navigation/features/map/data/datasources/places_search_source.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/domain/services/building_search.dart';
import 'package:mq_navigation/features/map/presentation/controllers/map_controller.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Draggable bottom sheet for finding campus buildings or nearby places.
///
/// Combines a local fuzzy-search of the campus building registry with a
/// debounced remote call to Google Places. When the user selects a remote place,
/// the app automatically switches to the Google Maps renderer and deep-links
/// out for directions, as campus data doesn't cover off-campus spots.
class BuildingSearchSheet extends ConsumerStatefulWidget {
  const BuildingSearchSheet({super.key});

  @override
  ConsumerState<BuildingSearchSheet> createState() =>
      _BuildingSearchSheetState();
}

class _BuildingSearchSheetState extends ConsumerState<BuildingSearchSheet> {
  late final TextEditingController _controller;
  Timer? _placesDebounce;
  List<PlaceSuggestion> _placeSuggestions = const [];
  bool _isLoadingPlaces = false;
  late final FocusNode _searchFocusNode;
  int _placesRequestVersion = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(mapControllerProvider).value?.searchQuery ?? '',
    );
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _placesDebounce?.cancel();
    _searchFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(mapControllerProvider.notifier).updateSearchQuery(value);
    _schedulePlacesSearch(value);
  }

  void _schedulePlacesSearch(String query) {
    _placesDebounce?.cancel();

    if (query.trim().length < 3) {
      _placesRequestVersion += 1;
      setState(() {
        _placeSuggestions = const [];
        _isLoadingPlaces = false;
      });
      return;
    }

    _placesDebounce = Timer(MqAnimations.adaptive(MqAnimations.slow, ref), () {
      final requestId = ++_placesRequestVersion;
      _fetchPlaceSuggestions(query, requestId);
    });
  }

  Future<void> _fetchPlaceSuggestions(String query, int requestId) async {
    final lowDataMode =
        ref.read(settingsControllerProvider).value?.lowDataMode ?? false;

    // Low Data Guard: skip calling maps-places Edge Function entirely
    if (lowDataMode) {
      return;
    }

    final state = ref.read(mapControllerProvider).value;
    final results = state?.searchResults ?? const <Building>[];
    final normalized = normalizeMapSearch(query);

    // Only fetch Places suggestions when campus search has no strong matches.
    final hasStrongMatch = results.any(
      (building) => isStrongCampusMatch(building, normalized),
    );
    if (hasStrongMatch) {
      if (requestId != _placesRequestVersion || !mounted) {
        return;
      }
      setState(() {
        _placeSuggestions = const [];
        _isLoadingPlaces = false;
      });
      return;
    }

    setState(() => _isLoadingPlaces = true);

    final location = state?.currentLocation;
    final suggestions = await ref
        .read(placesSearchSourceProvider)
        .search(
          query,
          latitude: location?.latitude,
          longitude: location?.longitude,
        );

    if (!mounted ||
        requestId != _placesRequestVersion ||
        normalizeMapSearch(_controller.text) != normalized) {
      return;
    }

    setState(() {
      _placeSuggestions = suggestions;
      _isLoadingPlaces = false;
    });
  }

  void _onPlaceTapped(PlaceSuggestion suggestion) {
    final haptics =
        ref.read(settingsControllerProvider).value?.hapticsEnabled ?? true;
    MqHaptics.selection(haptics);
    _searchFocusNode.unfocus();
    final controller = ref.read(mapControllerProvider.notifier);
    controller.setRenderer(MapRendererType.google);
    Navigator.of(context).pop();
    // Launch Google Maps directions to the place via deep-link.
    // We don't have GPS coordinates for the place, so use the place
    // description as a search query in Google Maps.
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${Uri.encodeComponent(suggestion.description)}',
    );
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final state = ref.watch(mapControllerProvider).value;
    final results = state?.searchResults ?? const <Building>[];
    final query = _controller.text.trim();
    final lowDataMode =
        ref.watch(settingsControllerProvider).value?.lowDataMode ?? false;
    final showPlacesSection =
        !lowDataMode &&
        query.length >= 3 &&
        (_placeSuggestions.isNotEmpty || _isLoadingPlaces);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.15,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const <double>[0.15, 0.5, 0.9],
      builder: (context, scrollController) {
        return Material(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(MqSpacing.space6),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(MqSpacing.space4),
            children: [
              TextField(
                controller: _controller,
                focusNode: _searchFocusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.searchBuildingsPlaceholder,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _searchFocusNode.unfocus(),
              ),
              const SizedBox(height: MqSpacing.space4),
              ...results.map(
                (building) => ListTile(
                  title: Text(building.name),
                  subtitle: Text(building.code),
                  onTap: () {
                    final haptics =
                        ref
                            .read(settingsControllerProvider)
                            .value
                            ?.hapticsEnabled ??
                        true;
                    MqHaptics.selection(haptics);
                    _searchFocusNode.unfocus();
                    ref
                        .read(mapControllerProvider.notifier)
                        .selectBuilding(building);
                    Navigator.of(context).pop();
                  },
                ),
              ),
              if (results.isEmpty && query.isNotEmpty && !_isLoadingPlaces)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: MqSpacing.space8,
                  ),
                  child: Center(
                    child: Text(
                      l10n.noBuildingsFound(query),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? MqColors.contentSecondaryDark
                            : MqColors.contentTertiary,
                      ),
                    ),
                  ),
                ),
              if (showPlacesSection) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: MqSpacing.space3,
                  ),
                  child: Divider(
                    color: isDark ? MqColors.charcoal600 : MqColors.sand300,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: MqSpacing.space4,
                    bottom: MqSpacing.space2,
                    top: MqSpacing.space1,
                  ),
                  child: Text(
                    l10n.nearbyPlaces,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? MqColors.contentSecondaryDark
                          : MqColors.contentSecondary,
                    ),
                  ),
                ),
                if (_isLoadingPlaces)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: MqSpacing.space4),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  ..._placeSuggestions.map(
                    (suggestion) => ListTile(
                      leading: Icon(
                        Icons.place,
                        color: isDark
                            ? MqColors.contentSecondaryDark
                            : MqColors.contentTertiary,
                      ),
                      title: Text(
                        suggestion.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      minVerticalPadding: MqSpacing.space2,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: MqSpacing.space4,
                      ),
                      onTap: () => _onPlaceTapped(suggestion),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}
