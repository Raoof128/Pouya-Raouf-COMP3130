import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/presentation/controllers/map_controller.dart';

class BuildingSearchSheet extends ConsumerStatefulWidget {
  const BuildingSearchSheet({super.key});

  @override
  ConsumerState<BuildingSearchSheet> createState() =>
      _BuildingSearchSheetState();
}

class _BuildingSearchSheetState extends ConsumerState<BuildingSearchSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(mapControllerProvider).value;
    final results = state?.searchResults ?? const <Building>[];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.15,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const <double>[0.15, 0.5, 0.9],
      builder: (context, scrollController) {
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: l10n.searchBuildingsPlaceholder,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) {
                  ref
                      .read(mapControllerProvider.notifier)
                      .updateSearchQuery(value);
                },
              ),
              const SizedBox(height: 16),
              ...results.map(
                (building) => ListTile(
                  title: Text(building.name),
                  subtitle: Text(building.id),
                  onTap: () {
                    ref
                        .read(mapControllerProvider.notifier)
                        .selectBuilding(building);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
