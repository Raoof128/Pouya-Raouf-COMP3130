import 'package:flutter/material.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/features/feed/domain/entities/feed_item.dart';

class FeedFilterBar extends StatelessWidget {
  const FeedFilterBar({
    super.key,
    required this.selectedTypes,
    required this.activeDateRange,
    required this.onToggleType,
    required this.onChangeDateRange,
  });

  final Set<FeedItemType> selectedTypes;
  final DateTimeRange? activeDateRange;
  final ValueChanged<FeedItemType> onToggleType;
  final VoidCallback onChangeDateRange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          selected: selectedTypes.contains(FeedItemType.event),
          label: Text(l10n.events),
          onSelected: (_) => onToggleType(FeedItemType.event),
        ),
        FilterChip(
          selected: selectedTypes.contains(FeedItemType.announcement),
          label: Text(l10n.announcements),
          onSelected: (_) => onToggleType(FeedItemType.announcement),
        ),
        FilterChip(
          selected: selectedTypes.contains(FeedItemType.featured),
          label: Text(l10n.featured),
          onSelected: (_) => onToggleType(FeedItemType.featured),
        ),
        ActionChip(
          avatar: const Icon(Icons.date_range_outlined, size: 18),
          label: Text(
            activeDateRange == null ? l10n.filter : l10n.clearFilters,
          ),
          onPressed: onChangeDateRange,
        ),
      ],
    );
  }
}
