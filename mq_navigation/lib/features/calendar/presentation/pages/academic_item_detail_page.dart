import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/features/calendar/data/repositories/calendar_repository.dart';
import 'package:mq_navigation/shared/models/academic_models.dart';
import 'package:mq_navigation/shared/widgets/mq_app_bar.dart';
import 'package:mq_navigation/shared/widgets/mq_card.dart';

enum AcademicItemDetailType { deadline, exam, event }

final _deadlineDetailProvider = FutureProvider.autoDispose
    .family<DeadlineItem?, String>((ref, id) {
      return ref.read(calendarRepositoryProvider).fetchDeadlineById(id);
    });

final _eventDetailProvider = FutureProvider.autoDispose
    .family<AcademicEvent?, String>((ref, id) {
      return ref.read(calendarRepositoryProvider).fetchEventById(id);
    });

class AcademicItemDetailPage extends ConsumerWidget {
  const AcademicItemDetailPage({
    required this.itemId,
    required this.detailType,
    super.key,
  });

  final String itemId;
  final AcademicItemDetailType detailType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: MqAppBar(title: _titleFor(l10n)),
      body: switch (detailType) {
        AcademicItemDetailType.deadline || AcademicItemDetailType.exam =>
          ref
              .watch(_deadlineDetailProvider(itemId))
              .when(
                data: (item) =>
                    _DeadlineDetailBody(item: item, expectedType: detailType),
                error: (error, _) => _DetailError(message: error.toString()),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
        AcademicItemDetailType.event =>
          ref
              .watch(_eventDetailProvider(itemId))
              .when(
                data: (item) => _EventDetailBody(item: item),
                error: (error, _) => _DetailError(message: error.toString()),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
      },
    );
  }

  String _titleFor(AppLocalizations l10n) {
    return switch (detailType) {
      AcademicItemDetailType.deadline => l10n.deadlineLabel,
      AcademicItemDetailType.exam => l10n.exam,
      AcademicItemDetailType.event => l10n.event,
    };
  }
}

class _DeadlineDetailBody extends StatelessWidget {
  const _DeadlineDetailBody({required this.item, required this.expectedType});

  final DeadlineItem? item;
  final AcademicItemDetailType expectedType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (item == null ||
        (expectedType == AcademicItemDetailType.exam && !item!.isExam) ||
        (expectedType == AcademicItemDetailType.deadline && item!.isExam)) {
      return _DetailNotFound(message: l10n.itemNoLongerAvailable);
    }

    final dueLabel = DateFormat(
      'EEE d MMM yyyy · h:mm a',
    ).format(item!.dueDate);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MqCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item!.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                item!.unitCode,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              _DetailRow(label: l10n.due, value: dueLabel),
              _DetailRow(label: l10n.priority, value: item!.priority),
              if ((item!.building ?? '').isNotEmpty)
                _DetailRow(label: l10n.building, value: item!.building!),
              if ((item!.room ?? '').isNotEmpty)
                _DetailRow(label: l10n.room, value: item!.room!),
              if ((item!.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  item!.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EventDetailBody extends StatelessWidget {
  const _EventDetailBody({required this.item});

  final AcademicEvent? item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (item == null) {
      return _DetailNotFound(message: l10n.itemNoLongerAvailable);
    }

    final startLabel = DateFormat(
      'EEE d MMM yyyy · h:mm a',
    ).format(item!.startAt);
    final endLabel = item!.endAt == null
        ? null
        : DateFormat('EEE d MMM yyyy · h:mm a').format(item!.endAt!);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        MqCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item!.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _DetailRow(label: l10n.starts, value: startLabel),
              if (endLabel != null)
                _DetailRow(label: l10n.ends, value: endLabel),
              if ((item!.location ?? '').isNotEmpty)
                _DetailRow(label: l10n.location, value: item!.location!),
              if ((item!.building ?? '').isNotEmpty)
                _DetailRow(label: l10n.building, value: item!.building!),
              if ((item!.room ?? '').isNotEmpty)
                _DetailRow(label: l10n.room, value: item!.room!),
              _DetailRow(label: l10n.category, value: item!.category),
              if ((item!.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  item!.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _DetailNotFound extends StatelessWidget {
  const _DetailNotFound({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
    );
  }
}
