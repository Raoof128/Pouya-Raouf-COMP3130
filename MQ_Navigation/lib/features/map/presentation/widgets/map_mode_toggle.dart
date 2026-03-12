import 'package:flutter/material.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';

class MapModeToggle extends StatelessWidget {
  const MapModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final MapRendererType value;
  final ValueChanged<MapRendererType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SegmentedButton<MapRendererType>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: MapRendererType.campus,
          icon: const Icon(Icons.map_outlined, size: 18),
          label: FittedBox(child: Text(l10n.campusMap)),
        ),
        ButtonSegment(
          value: MapRendererType.google,
          icon: const Icon(Icons.public, size: 18),
          label: FittedBox(child: Text(l10n.googleMaps)),
        ),
      ],
      selected: <MapRendererType>{value},
      onSelectionChanged: (selection) {
        onChanged(selection.first);
      },
    );
  }
}
