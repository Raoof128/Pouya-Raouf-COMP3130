import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/open_day/data/open_day_providers.dart';
import 'package:mq_navigation/features/open_day/domain/entities/open_day_data.dart';
import 'package:mq_navigation/features/open_day/domain/services/open_day_time.dart';
import 'package:mq_navigation/features/open_day/presentation/widgets/bachelor_picker_sheet.dart';
import 'package:mq_navigation/features/open_day/presentation/widgets/event_actions_sheet.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_tactile_button.dart';

/// Dedicated Open Day screen. Lists events relevant to the user's
/// selected bachelor, grouped by time. If no bachelor has been picked,
/// shows a gentle CTA to pick one — the screen still works; it just
/// shows fewer events.
class OpenDayPage extends ConsumerWidget {
  const OpenDayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = context.isDarkMode;
    final dataAsync = ref.watch(openDayDataProvider);
    final selected = ref.watch(selectedBachelorProvider);
    final events = ref.watch(relevantOpenDayEventsProvider);

    return Scaffold(
      backgroundColor: dark ? MqColors.charcoal800 : MqColors.alabaster,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // GoRouter renders `/open-day` outside the bottom-nav shell, so
        // `automaticallyImplyLeading` doesn't always discover a back
        // affordance reliably. Wire one explicitly: pop if there's a
        // route to pop to (deep-link from Home), otherwise route the
        // user to Home — never a dead screen.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteNames.home);
            }
          },
        ),
        title: Text(
          'Open Day',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(MqSpacing.space6),
            child: Text(
              'Couldn\'t load Open Day data. Please try again later.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
          ),
        ),
        data: (data) =>
            _OpenDayBody(data: data, selected: selected, events: events),
      ),
    );
  }
}

class _OpenDayBody extends StatelessWidget {
  const _OpenDayBody({
    required this.data,
    required this.selected,
    required this.events,
  });

  final OpenDayData data;
  final OpenDayBachelor? selected;
  final List<OpenDayEvent> events;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        MqSpacing.space5,
        MqSpacing.space2,
        MqSpacing.space5,
        MqSpacing.space12,
      ),
      children: [
        _StudyInterestHeader(selected: selected, openDayDate: data.openDayDate),
        const SizedBox(height: MqSpacing.space5),
        if (events.isEmpty)
          _EmptyEventsState(hasSelection: selected != null)
        else
          ..._groupedByHour(events),
      ],
    );
  }

  /// Builds a list of widgets where consecutive events sharing the same
  /// hour are visually grouped under a single time header.
  ///
  /// Hour-grouping uses `OpenDayTime.sydneyHour` so events that share an
  /// hour in Sydney always cluster together, regardless of device TZ.
  /// Headers and tile times use the same Sydney-aware formatter, so a
  /// 1:00 PM event reads as "1:00 PM" everywhere — never "3:00 AM" on
  /// a UTC device.
  List<Widget> _groupedByHour(List<OpenDayEvent> events) {
    final out = <Widget>[];
    int? currentHour;
    for (final e in events) {
      final hourKey = OpenDayTime.sydneyHour(e.startTime);
      if (hourKey != currentHour) {
        currentHour = hourKey;
        out.add(
          _TimeBlockHeader(label: OpenDayTime.formatTimeOfDay(e.startTime)),
        );
      }
      out.add(_EventTile(event: e));
      out.add(const SizedBox(height: MqSpacing.space3));
    }
    return out;
  }
}

class _StudyInterestHeader extends ConsumerWidget {
  const _StudyInterestHeader({
    required this.selected,
    required this.openDayDate,
  });

  final OpenDayBachelor? selected;
  final DateTime openDayDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = context.isDarkMode;
    final dateText = OpenDayTime.formatLongDate(openDayDate);

    return Container(
      padding: const EdgeInsetsDirectional.all(MqSpacing.space4),
      decoration: BoxDecoration(
        color: dark
            ? MqColors.charcoal800.withAlpha(20)
            : MqColors.red.withAlpha(14),
        borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
        border: Border.all(
          color: dark
              ? MqColors.charcoal800.withAlpha(70)
              : MqColors.red.withAlpha(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateText.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: dark ? MqColors.charcoal800 : MqColors.red,
            ),
          ),
          const SizedBox(height: MqSpacing.space1),
          Text(
            selected == null
                ? 'Pick what you\'re interested in'
                : selected!.name,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: dark ? Colors.white : MqColors.contentPrimary,
            ),
          ),
          const SizedBox(height: MqSpacing.space1),
          Text(
            selected == null
                ? 'Choose a bachelor to filter the schedule. Stays on this device.'
                : 'Showing info sessions matched to your study interest.',
            style: context.textTheme.bodySmall?.copyWith(
              color: dark
                  ? Colors.white.withValues(alpha: 0.78)
                  : MqColors.contentSecondary,
            ),
          ),
          const SizedBox(height: MqSpacing.space3),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => BachelorPickerSheet.show(context),
              style: TextButton.styleFrom(
                foregroundColor: dark ? MqColors.charcoal800 : MqColors.red,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: MqSpacing.space3,
                  vertical: MqSpacing.space1,
                ),
              ),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: Text(selected == null ? 'Choose interest' : 'Change'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBlockHeader extends StatelessWidget {
  const _TimeBlockHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: MqSpacing.space4,
        bottom: MqSpacing.space2,
        start: MqSpacing.space1,
      ),
      child: Text(
        label.toUpperCase(),
        style: context.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: dark ? MqColors.charcoal800 : MqColors.red,
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final OpenDayEvent event;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    final timeRange = OpenDayTime.formatTimeRange(
      event.startTime,
      event.endTime,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? MqColors.charcoal800 : Colors.white,
        borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
        border: Border.all(
          color: dark ? Colors.white.withAlpha(13) : MqColors.sand200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                MqSpacing.space4,
                MqSpacing.space3,
                MqSpacing.space2,
                MqSpacing.space3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : MqColors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$timeRange  ·  ${event.venueName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.72)
                          : MqColors.contentSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Direction action: opens an action sheet rather than going
          // straight to a single destination, since we want the user to
          // consciously choose between in-app context and external nav.
          Semantics(
            button: true,
            label: 'Directions to ${event.venueName}',
            child: MqTactileButton(
              onTap: () => EventActionsSheet.show(context, event),
              borderRadius: MqSpacing.radiusXl,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: MqSpacing.space4,
                  vertical: MqSpacing.space3,
                ),
                child: Icon(
                  Icons.directions_rounded,
                  size: 24,
                  color: dark ? MqColors.charcoal800 : MqColors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEventsState extends StatelessWidget {
  const _EmptyEventsState({required this.hasSelection});

  final bool hasSelection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.all(MqSpacing.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 48,
            color: context.isDarkMode
                ? MqColors.slate500
                : MqColors.charcoal600,
          ),
          const SizedBox(height: MqSpacing.space3),
          Text(
            hasSelection
                ? 'No events matched to your study interest yet.'
                : 'Pick what you\'re interested in to see relevant events.',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
