import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/domain/entities/building.dart';
import 'package:mq_navigation/features/map/presentation/pages/directions_page.dart';

/// Detail page for a single campus building.
///
/// Uses a [SliverAppBar] with a hero image (if available) and displays
/// building metadata such as category, floors, wheelchair access, and
/// a "Get Directions" button.
class BuildingDetailPage extends StatelessWidget {
  const BuildingDetailPage({super.key, required this.building});

  final Building building;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                building.name,
                style: const TextStyle(shadows: [
                  Shadow(blurRadius: 8, color: Colors.black54),
                ]),
              ),
              background: building.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: building.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: MqColors.slate200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => _defaultBackground(),
                    )
                  : _defaultBackground(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(MqSpacing.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Chip(
                    avatar: Icon(
                      _iconForCategory(building.category),
                      size: 18,
                    ),
                    label: Text(building.category.label),
                  ),
                  const SizedBox(height: MqSpacing.space4),

                  // Description
                  Text(
                    building.description ?? 'No description available.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: MqSpacing.space4),

                  // Metadata
                  if (building.levels != null)
                    _MetadataRow(
                      icon: Icons.layers,
                      label: '${building.levels} floors',
                    ),
                  if (building.wheelchair)
                    const _MetadataRow(
                      icon: Icons.accessible,
                      label: 'Wheelchair accessible',
                    ),
                  if (building.address != null)
                    _MetadataRow(
                      icon: Icons.location_on,
                      label: building.address!,
                    ),
                  if (building.gridRef != null)
                    _MetadataRow(
                      icon: Icons.grid_on,
                      label: 'Grid: ${building.gridRef}',
                    ),

                  // Tags
                  if (building.tags.isNotEmpty) ...[
                    const SizedBox(height: MqSpacing.space4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: building.tags
                          .map((t) => Chip(label: Text(t)))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: MqSpacing.space6),

                  // Get Directions button
                  if (building.latitude != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.directions_walk),
                        label: const Text('Get Directions'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  DirectionsPage(destination: building),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [MqColors.slate300, MqColors.slate100],
        ),
      ),
      child: const Center(
        child: Icon(Icons.domain, size: 64, color: MqColors.charcoal600),
      ),
    );
  }

  IconData _iconForCategory(BuildingCategory category) {
    switch (category) {
      case BuildingCategory.academic:
        return Icons.school;
      case BuildingCategory.food:
        return Icons.restaurant;
      case BuildingCategory.health:
        return Icons.local_hospital;
      case BuildingCategory.sports:
        return Icons.fitness_center;
      case BuildingCategory.services:
        return Icons.miscellaneous_services;
      case BuildingCategory.venue:
        return Icons.theater_comedy;
      case BuildingCategory.research:
        return Icons.science;
      case BuildingCategory.residential:
        return Icons.home;
      case BuildingCategory.other:
        return Icons.place;
    }
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MqSpacing.space2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: MqColors.charcoal600),
          const SizedBox(width: MqSpacing.space2),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
