import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/open_day/data/open_day_providers.dart';
import 'package:mq_navigation/features/open_day/domain/entities/open_day_data.dart';
import 'package:mq_navigation/features/open_day/domain/services/open_day_time.dart';
import 'package:mq_navigation/features/open_day/presentation/widgets/bachelor_picker_sheet.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_tactile_button.dart';

/// Compact Home-screen card that morphs based on selection state:
///
///  • **No selection** → onboarding CTA: "What are you interested in?"
///    Tapping opens the bachelor picker sheet. Lightweight, dismissible.
///  • **Has selection** → preview: shows the selected bachelor and the
///    next 1–2 upcoming events, plus a "View schedule" CTA into the
///    dedicated Open Day page.
///
/// The card hides itself entirely when the Open Day dataset fails to
/// load — Open Day is an enhancement, not a navigation requirement, so
/// degrading silently is preferable to showing an error on Home.
class OpenDayHomeCard extends ConsumerWidget {
  const OpenDayHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(openDayDataProvider);
    if (dataAsync is! AsyncData<OpenDayData>) return const SizedBox.shrink();

    final data = dataAsync.value;
    final selected = ref.watch(selectedBachelorProvider);
    final events = ref.watch(relevantOpenDayEventsProvider);

    return selected == null
        ? _OnboardingCard(openDayDate: data.openDayDate)
        : _PreviewCard(
            selected: selected,
            upcoming: events.take(2).toList(),
            openDayDate: data.openDayDate,
          );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({required this.openDayDate});

  final DateTime openDayDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = context.isDarkMode;
    final dateText = OpenDayTime.formatShortDate(openDayDate);

    return MqTactileButton(
      onTap: () => BachelorPickerSheet.show(context),
      borderRadius: MqSpacing.radiusXl,
      // Same glassy white surface as the Metro Countdown card above —
      // gives the Open Day onboarding affordance a proper card
      // container so it reads as an intentional surface rather than a
      // translucent red wash floating over the campus background.
      // The red identity moves to the icon + uppercase eyebrow text,
      // not to the surface itself.
      child: Container(
        padding: const EdgeInsetsDirectional.all(MqSpacing.space4),
        decoration: BoxDecoration(
          color: dark
              ? MqColors.charcoal800.withValues(alpha: 0.94)
              : Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : MqColors.charcoal800.withValues(alpha: 0.06),
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: MqColors.charcoal800.withValues(alpha: dark ? 0.30 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: MqColors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: MqSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.openDay_headerWithDate(dateText).toUpperCase(),
                    style: context.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: MqColors.red,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.openDay_interestedInStudying,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : MqColors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.openDay_pickBachelorCta,
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
            const Icon(Icons.chevron_right_rounded, color: MqColors.brightRed),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.selected,
    required this.upcoming,
    required this.openDayDate,
  });

  final OpenDayBachelor selected;
  final List<OpenDayEvent> upcoming;
  final DateTime openDayDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = context.isDarkMode;
    final dateText = OpenDayTime.formatShortDate(openDayDate);

    return MqTactileButton(
      onTap: () => context.goNamed(RouteNames.openDay),
      borderRadius: MqSpacing.radiusXl,
      child: Container(
        padding: const EdgeInsetsDirectional.all(MqSpacing.space4),
        decoration: BoxDecoration(
          color: dark
              ? MqColors.charcoal800.withValues(alpha: 0.94)
              : Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : MqColors.charcoal800.withValues(alpha: 0.06),
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: MqColors.charcoal800.withValues(alpha: dark ? 0.30 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.openDay_headerWithDate(dateText),
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: MqColors.red,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: MqColors.brightRed,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              selected.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : MqColors.contentPrimary,
              ),
            ),
            if (upcoming.isEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4),
                child: Text(
                  l10n.openDay_noSessionsYet,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.72)
                        : MqColors.contentSecondary,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final e in upcoming) _MicroEventRow(event: e),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MicroEventRow extends StatelessWidget {
  const _MicroEventRow({required this.event});

  final OpenDayEvent event;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    final time = OpenDayTime.formatTimeOfDay(event.startTime);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 2),
      child: Text(
        '$time  ·  ${event.venueName}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodySmall?.copyWith(
          color: dark
              ? Colors.white.withValues(alpha: 0.78)
              : MqColors.contentSecondary,
        ),
      ),
    );
  }
}
