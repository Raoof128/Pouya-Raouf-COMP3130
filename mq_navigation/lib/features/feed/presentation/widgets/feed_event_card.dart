import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/features/feed/domain/entities/feed_item.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';
import 'package:mq_navigation/shared/widgets/mq_card.dart';

class FeedEventCard extends StatelessWidget {
  const FeedEventCard({
    super.key,
    required this.item,
    required this.isInCalendar,
    required this.onAddToCalendar,
  });

  final FeedItem item;
  final bool isInCalendar;
  final VoidCallback onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateLabel = DateFormat('EEE d MMM · h:mm a').format(item.startAt);

    return MqCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TypeChip(type: item.type),
              if (item.isFeatured)
                Chip(
                  label: Text(l10n.featured),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(item.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(dateLabel, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(item.subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text(item.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          MqButton(
            label: isInCalendar
                ? l10n.eventAlreadyInCalendar
                : l10n.addToCalendar,
            variant: isInCalendar
                ? MqButtonVariant.outlined
                : MqButtonVariant.filled,
            onPressed: isInCalendar ? null : onAddToCalendar,
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final FeedItemType type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (type) {
      FeedItemType.event => l10n.events,
      FeedItemType.announcement => l10n.announcements,
      FeedItemType.featured => l10n.featured,
    };
    return Chip(label: Text(label), visualDensity: VisualDensity.compact);
  }
}
