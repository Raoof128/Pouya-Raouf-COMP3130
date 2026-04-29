import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/open_day/data/open_day_providers.dart';
import 'package:mq_navigation/features/open_day/domain/entities/open_day_data.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_bottom_sheet.dart';

/// Lightweight, non-blocking bachelor picker. Surfaces as a bottom sheet
/// so it never feels like an account-setup wall — the user can dismiss
/// and the app keeps working without a selection.
///
/// Bachelors are grouped under their study area for fast scanning. Tapping
/// a row immediately commits the choice (no "Save" button) — this is a
/// preference, not a form submission.
class BachelorPickerSheet extends ConsumerWidget {
  const BachelorPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const BachelorPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = context.isDarkMode;
    final dataAsync = ref.watch(openDayDataProvider);
    final selectedId = ref
        .watch(settingsControllerProvider)
        .value
        ?.selectedBachelorId;

    return MqBottomSheet(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                MqSpacing.space2,
                0,
                MqSpacing.space2,
                MqSpacing.space2,
              ),
              child: Text(
                'What are you interested in studying?',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: dark
                      ? MqColors.contentPrimaryDark
                      : MqColors.contentPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                MqSpacing.space2,
                0,
                MqSpacing.space2,
                MqSpacing.space4,
              ),
              child: Text(
                'Pick a bachelor program — this stays on your device and personalises your Open Day events.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.72)
                      : MqColors.contentSecondary,
                ),
              ),
            ),
            Flexible(
              child: dataAsync.when(
                data: (data) =>
                    _BachelorList(data: data, selectedId: selectedId),
                loading: () => const Padding(
                  padding: EdgeInsetsDirectional.all(MqSpacing.space6),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsetsDirectional.all(MqSpacing.space6),
                  child: Text(
                    'Couldn\'t load Open Day data. Please try again later.',
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
            if (selectedId != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: MqSpacing.space2,
                  horizontal: MqSpacing.space2,
                ),
                child: TextButton.icon(
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Clear my selection'),
                  style: TextButton.styleFrom(
                    foregroundColor: dark
                        ? Colors.white.withValues(alpha: 0.85)
                        : MqColors.contentSecondary,
                  ),
                  onPressed: () async {
                    await ref
                        .read(settingsControllerProvider.notifier)
                        .updateSelectedBachelorId(null);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BachelorList extends ConsumerWidget {
  const _BachelorList({required this.data, required this.selectedId});

  final OpenDayData data;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group bachelors by study area for fast visual scanning.
    final byArea = <String, List<OpenDayBachelor>>{};
    for (final b in data.bachelors) {
      byArea.putIfAbsent(b.studyAreaId, () => <OpenDayBachelor>[]).add(b);
    }

    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        for (final area in data.studyAreas)
          if (byArea[area.id] != null)
            _AreaSection(
              area: area,
              bachelors: byArea[area.id]!,
              selectedId: selectedId,
              onSelect: (b) async {
                await ref
                    .read(settingsControllerProvider.notifier)
                    .updateSelectedBachelorId(b.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
      ],
    );
  }
}

class _AreaSection extends StatelessWidget {
  const _AreaSection({
    required this.area,
    required this.bachelors,
    required this.selectedId,
    required this.onSelect,
  });

  final OpenDayStudyArea area;
  final List<OpenDayBachelor> bachelors;
  final String? selectedId;
  final void Function(OpenDayBachelor) onSelect;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            MqSpacing.space2,
            MqSpacing.space3,
            MqSpacing.space2,
            MqSpacing.space1,
          ),
          child: Text(
            area.name.toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: dark ? MqColors.vividRed : MqColors.red,
            ),
          ),
        ),
        for (final b in bachelors)
          ListTile(
            dense: true,
            title: Text(
              b.name,
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: b.id == selectedId
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: b.id == selectedId
                    ? (dark ? MqColors.vividRed : MqColors.red)
                    : (dark
                          ? MqColors.contentPrimaryDark
                          : MqColors.contentPrimary),
              ),
            ),
            trailing: b.id == selectedId
                ? const Icon(
                    Icons.check_rounded,
                    color: MqColors.vividRed,
                    size: 20,
                  )
                : null,
            onTap: () => onSelect(b),
          ),
      ],
    );
  }
}
