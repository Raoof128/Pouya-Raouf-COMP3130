import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/core/utils/haptics.dart';
import 'package:mq_navigation/features/map/domain/entities/map_renderer_type.dart';
import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';
import 'package:mq_navigation/features/map/data/services/offline_maps_service.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_navigation/features/transit/domain/entities/transit_stop.dart';
import 'package:mq_navigation/features/transit/presentation/providers/tfnsw_provider.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/models/user_preferences.dart';
import 'package:mq_navigation/shared/widgets/mq_bottom_sheet.dart';
import 'package:mq_navigation/shared/widgets/mq_input.dart';
import 'package:mq_navigation/shared/widgets/mq_tactile_button.dart';

/// Main settings screen for managing app-wide preferences.
///
/// Reacts to changes in [SettingsController]. Uses custom styled widgets
/// rather than standard Material tiles to match the MQ design system,
/// including a red radial gradient background in dark mode.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  int _versionTapCount = 0;

  void _handleVersionTap() {
    _versionTapCount++;
    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
      MqHaptics.heavy(true); // Always vibrate for the easter egg!

      final l10n = AppLocalizations.of(context)!;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => MqBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🛠️ ${l10n.devDiagnostics}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: MqSpacing.space2),
              Text(l10n.buildVersion),
              Text(l10n.renderer),
              Text(l10n.edgeProxy),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsState = ref.watch(settingsControllerProvider);
    final dark = context.isDarkMode;

    return Scaffold(
      backgroundColor: dark ? MqColors.charcoal850 : MqColors.alabaster,
      body: settingsState.when(
        data: (preferences) {
          return Stack(
            children: [
              // Red glow gradient — dark mode only.
              if (dark)
                Positioned(
                  top: -80,
                  left: 0,
                  right: 0,
                  height: 360,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -1.2),
                          radius: 1.1,
                          colors: [
                            MqColors.red.withAlpha(38),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              SafeArea(
                child: ListView(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    MqSpacing.space5,
                    MqSpacing.space6,
                    MqSpacing.space5,
                    MqSpacing.space12,
                  ),
                  children: [
                    // ── Page title ──────────────────────────────
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: MqSpacing.space1,
                        bottom: MqSpacing.space6,
                      ),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Transform.translate(
                              offset: Offset(0, 15 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          l10n.settings.toUpperCase(),
                          style: context.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: MqColors.red,
                          ),
                        ),
                      ),
                    ),

                    // ── General section ─────────────────────────
                    _SectionHeader(title: l10n.settings_general),
                    _SettingsCard(
                      children: [
                        _TapRow(
                          icon: Icons.dark_mode_outlined,
                          label: l10n.appearance,
                          value: switch (preferences.themeMode) {
                            ThemeMode.system => l10n.system,
                            ThemeMode.light => l10n.light,
                            ThemeMode.dark => l10n.dark,
                          },
                          semanticLabel: l10n.appearance,
                          hapticsEnabled: preferences.hapticsEnabled,
                          onTap: () => _showPicker<ThemeMode>(
                            context: context,
                            title: l10n.appearance,
                            current: preferences.themeMode,
                            items: ThemeMode.values,
                            labelOf: (v) => switch (v) {
                              ThemeMode.system => l10n.system,
                              ThemeMode.light => l10n.light,
                              ThemeMode.dark => l10n.dark,
                            },
                            onSelect: (v) => ref
                                .read(settingsControllerProvider.notifier)
                                .updateThemeMode(v),
                          ),
                        ),
                        _TapRow(
                          icon: Icons.language_outlined,
                          label: l10n.language,
                          value: _languageLabel(preferences.localeCode, l10n),
                          semanticLabel: l10n.language,
                          hapticsEnabled: preferences.hapticsEnabled,
                          onTap: () => _showPicker<String?>(
                            context: context,
                            title: l10n.language,
                            current: preferences.localeCode,
                            items: _localeCodes,
                            labelOf: (v) => _languageLabel(v, l10n),
                            onSelect: (v) => ref
                                .read(settingsControllerProvider.notifier)
                                .updateLocaleCode(v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MqSpacing.space6),

                    // ── Map Preferences section ───────────────────
                    _SectionHeader(
                      title: l10n.settings_experience,
                    ), // Using experience for map prefs
                    _SettingsCard(
                      children: [
                        _TapRow(
                          icon: Icons.map_outlined,
                          label: l10n.defaultRenderer,
                          value:
                              preferences.defaultRenderer ==
                                  MapRendererType.campus
                              ? l10n.campusRenderer
                              : l10n.googleRenderer,
                          semanticLabel: l10n.defaultRenderer,
                          hapticsEnabled: preferences.hapticsEnabled,
                          onTap: () => _showPicker<MapRendererType>(
                            context: context,
                            title: l10n.defaultRenderer,
                            current: preferences.defaultRenderer,
                            items: MapRendererType.values,
                            labelOf: (v) => v == MapRendererType.campus
                                ? l10n.campusRenderer
                                : l10n.googleRenderer,
                            onSelect: (v) => ref
                                .read(settingsControllerProvider.notifier)
                                .updateDefaultRenderer(v),
                          ),
                        ),
                        _TapRow(
                          icon: Icons.directions_walk_outlined,
                          label: l10n.defaultTravelMode,
                          value: switch (preferences.defaultTravelMode) {
                            TravelMode.walk => l10n.walk,
                            TravelMode.drive => l10n.drive,
                            TravelMode.bike => l10n.bike,
                            TravelMode.transit => l10n.transit,
                          },
                          semanticLabel: l10n.defaultTravelMode,
                          hapticsEnabled: preferences.hapticsEnabled,
                          onTap: () => _showPicker<TravelMode>(
                            context: context,
                            title: l10n.defaultTravelMode,
                            current: preferences.defaultTravelMode,
                            items: TravelMode.values,
                            labelOf: (v) => switch (v) {
                              TravelMode.walk => l10n.walk,
                              TravelMode.drive => l10n.drive,
                              TravelMode.bike => l10n.bike,
                              TravelMode.transit => l10n.transit,
                            },
                            onSelect: (v) => ref
                                .read(settingsControllerProvider.notifier)
                                .updateDefaultTravelMode(v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MqSpacing.space6),

                    // ── Commute Preferences section ───────────────
                    //
                    // Placed high on the page because these preferences
                    // are the ones that most directly change what the
                    // user sees on the Home screen (Metro Countdown).
                    _SectionHeader(title: l10n.commutePreferences),
                    _CommutePreviewTile(
                      mode: preferences.commuteMode,
                      route: preferences.favoriteRoute,
                      stopId: preferences.favoriteStopId,
                      l10n: l10n,
                    ),
                    _SettingsCard(
                      children: [
                        _TapRow(
                          icon: Icons.commute_outlined,
                          label: l10n.mainTransport,
                          value: switch (preferences.commuteMode) {
                            'metro' => l10n.commuteModeMetro,
                            'bus' => l10n.commuteModeBus,
                            'train' => l10n.commuteModeTrain,
                            _ => l10n.commuteModeNotSet,
                          },
                          semanticLabel: l10n.mainTransport,
                          hapticsEnabled: preferences.hapticsEnabled,
                          onTap: () => _showPicker<String>(
                            context: context,
                            title: l10n.mainTransport,
                            current: preferences.commuteMode,
                            items: const ['none', 'metro', 'bus', 'train'],
                            labelOf: (v) => switch (v) {
                              'metro' => l10n.commuteModeMetro,
                              'bus' => l10n.commuteModeBus,
                              'train' => l10n.commuteModeTrain,
                              _ => l10n.commuteModeNotSet,
                            },
                            onSelect: (v) => ref
                                .read(settingsControllerProvider.notifier)
                                .updateCommutePreferences(commuteMode: v),
                          ),
                        ),
                        if (preferences.commuteMode != 'none')
                          _TapRow(
                            icon: Icons.route_outlined,
                            label: l10n.favoriteRouteLine,
                            value: preferences.favoriteRoute.trim().isEmpty
                                ? l10n.setRoutePrompt
                                : preferences.favoriteRoute,
                            semanticLabel: l10n.favoriteRouteLine,
                            hapticsEnabled: preferences.hapticsEnabled,
                            onTap: () => _showRouteInputDialog(
                              context: context,
                              currentRoute: preferences.favoriteRoute,
                              ref: ref,
                            ),
                          ),
                        if (preferences.commuteMode != 'none')
                          _TapRow(
                            icon: Icons.pin_drop_outlined,
                            label: l10n.favoriteStopIdLabel,
                            value: _preferredStopLabel(preferences, l10n),
                            semanticLabel: l10n.favoriteStopIdLabel,
                            hapticsEnabled: preferences.hapticsEnabled,
                            onTap: () => _showStopSearchDialog(
                              context: context,
                              mode: preferences.commuteMode,
                              ref: ref,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: MqSpacing.space6),

                    // ── Accessibility & Data section ────────────
                    _SectionHeader(title: l10n.accessibility),
                    _SettingsCard(
                      children: [
                        _ToggleRow(
                          icon: Icons.download_for_offline_outlined,
                          label: l10n.offlineCampusMaps,
                          value: preferences.offlineCampusMapsEnabled,
                          semanticLabel: l10n.offlineCampusMaps,
                          hapticsEnabled: preferences.hapticsEnabled,
                          onChanged: (v) => ref
                              .read(settingsControllerProvider.notifier)
                              .updateOfflineCampusMapsEnabled(v),
                        ),
                        if (preferences.offlineCampusMapsEnabled)
                          _TapRow(
                            icon: Icons.cloud_download_outlined,
                            label: l10n.offlineCampusMapsDownload,
                            value: '',
                            semanticLabel: l10n.offlineCampusMapsDownload,
                            hapticsEnabled: preferences.hapticsEnabled,
                            onTap: () async {
                              if (!context.mounted) {
                                return;
                              }
                              context.showSnackBar(
                                l10n.offlineCampusMapsDownloading,
                              );
                              await ref
                                  .read(offlineMapsServiceProvider)
                                  .downloadCampusTiles();
                              if (context.mounted) {
                                context.showSnackBar(
                                  l10n.offlineCampusMapsReady,
                                );
                              }
                            },
                          ),
                        _ToggleRow(
                          icon: Icons.motion_photos_off_outlined,
                          label: l10n.reducedMotion,
                          value: preferences.reducedMotion,
                          semanticLabel: l10n.reducedMotion,
                          hapticsEnabled: preferences.hapticsEnabled,
                          onChanged: (v) => ref
                              .read(settingsControllerProvider.notifier)
                              .updateReducedMotion(v),
                        ),
                        _ToggleRow(
                          icon: Icons.vibration_outlined,
                          label: l10n.haptics,
                          value: preferences.hapticsEnabled,
                          semanticLabel: l10n.haptics,
                          hapticsEnabled: preferences.hapticsEnabled,
                          onChanged: (v) => ref
                              .read(settingsControllerProvider.notifier)
                              .updateHapticsEnabled(v),
                        ),
                        _ToggleRow(
                          icon: Icons.contrast_outlined,
                          label: l10n.highContrastMap,
                          value: preferences.highContrastMap,
                          semanticLabel: l10n.highContrastMap,
                          hapticsEnabled: preferences.hapticsEnabled,
                          onChanged: (v) => ref
                              .read(settingsControllerProvider.notifier)
                              .updateHighContrastMap(v),
                        ),
                        _ToggleRow(
                          icon: Icons.data_usage_outlined,
                          label: l10n.lowDataMode,
                          value: preferences.lowDataMode,
                          semanticLabel: l10n.lowDataMode,
                          hapticsEnabled: preferences.hapticsEnabled,
                          onChanged: (v) => ref
                              .read(settingsControllerProvider.notifier)
                              .updateLowDataMode(v),
                        ),
                      ],
                    ),
                    const SizedBox(height: MqSpacing.space6),

                    // ── Notifications section ───────────────────
                    _SectionHeader(title: l10n.notifications),
                    _SettingsCard(
                      children: [
                        _ToggleRow(
                          icon: Icons.notifications_outlined,
                          label: l10n.notifications,
                          value: preferences.notificationsEnabled,
                          semanticLabel: l10n.notifications,
                          hapticsEnabled: preferences.hapticsEnabled,
                          onChanged: (v) async {
                            final msg = await ref
                                .read(settingsControllerProvider.notifier)
                                .updateNotificationsEnabled(v);
                            if (msg != null && context.mounted) {
                              context.showSnackBar(msg, isError: true);
                            }
                          },
                        ),
                        _ToggleRow(
                          icon: Icons.bedtime_outlined,
                          label: l10n.quietHours,
                          value: preferences.quietHoursEnabled,
                          semanticLabel: l10n.quietHours,
                          hapticsEnabled: preferences.hapticsEnabled,
                          onChanged: (v) => ref
                              .read(settingsControllerProvider.notifier)
                              .updateQuietHoursEnabled(v),
                        ),
                        if (preferences.quietHoursEnabled) ...[
                          _TapRow(
                            icon: Icons.access_time_outlined,
                            label: l10n.quietHoursStart,
                            value: preferences.quietHoursStart,
                            hapticsEnabled: preferences.hapticsEnabled,
                            onTap: () => _selectTime(
                              context,
                              preferences.quietHoursStart,
                              (time) => ref
                                  .read(settingsControllerProvider.notifier)
                                  .updateQuietHoursStart(time),
                            ),
                          ),
                          _TapRow(
                            icon: Icons.access_time_filled_outlined,
                            label: l10n.quietHoursEnd,
                            value: preferences.quietHoursEnd,
                            hapticsEnabled: preferences.hapticsEnabled,
                            onTap: () => _selectTime(
                              context,
                              preferences.quietHoursEnd,
                              (time) => ref
                                  .read(settingsControllerProvider.notifier)
                                  .updateQuietHoursEnd(time),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: MqSpacing.space6),

                    // ── About section ────────────────────────────
                    _SectionHeader(title: l10n.about),
                    _SettingsCard(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _handleVersionTap,
                          child: _AboutAppRow(
                            appName: l10n.appName,
                            desc: l10n.aboutDesc,
                          ),
                        ),
                        _InfoRow(
                          icon: Icons.code_outlined,
                          label: l10n.version,
                          subtitle: '1.0.0',
                        ),
                        _InfoRow(
                          icon: Icons.people_outline,
                          label: l10n.about_theTeam,
                          subtitle: l10n.about_theTeam_desc,
                        ),
                      ],
                    ),
                    const SizedBox(height: MqSpacing.space6),

                    // ── Danger Zone section ──────────────────────
                    //
                    // Trailing position is deliberate — destructive
                    // actions should not appear above About/read-only
                    // content where they could be triggered absent-
                    // mindedly while skimming the page.
                    _SectionHeader(title: l10n.dangerZone),
                    _DangerZoneCard(
                      hapticsEnabled: preferences.hapticsEnabled,
                      onTap: () => _confirmWipe(context, ref, l10n),
                      subtitle: l10n.wipeDataConfirm,
                      title: l10n.wipeData,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsetsDirectional.all(MqSpacing.space6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: dark ? MqColors.slate500 : MqColors.charcoal600,
                ),
                const SizedBox(height: MqSpacing.space4),
                Text(l10n.settingsError, textAlign: TextAlign.center),
                const SizedBox(height: MqSpacing.space4),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(settingsControllerProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.loading.replaceAll('...', '')),
                ),
              ],
            ),
          ),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: MqColors.red)),
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    String current,
    Function(String) onSelect,
  ) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      onSelect('$hour:$minute');
    }
  }

  Future<void> _confirmWipe(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.wipeData),
        content: Text(l10n.wipeDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: MqColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.wipeDataAction),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final msg = await ref
          .read(settingsControllerProvider.notifier)
          .wipeAllLocalData();
      if (msg != null && context.mounted) {
        context.showSnackBar(msg, isError: true);
      } else if (context.mounted) {
        context.showSnackBar(l10n.wipeDataSuccess);
      }
    }
  }

  Future<void> _showRouteInputDialog({
    required BuildContext context,
    required String currentRoute,
    required WidgetRef ref,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentRoute);
    try {
      final saved = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            l10n.favoriteRouteTitle,
            style: const TextStyle(color: MqColors.contentPrimary),
          ),
          content: MqInput(
            controller: controller,
            hint: l10n.favoriteRouteHint,
            label: l10n.favoriteRouteLine,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: MqColors.contentSecondary),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: Text(
                l10n.save,
                style: const TextStyle(color: MqColors.red),
              ),
            ),
          ],
        ),
      );
      if (saved != null && context.mounted) {
        final message = await ref
            .read(settingsControllerProvider.notifier)
            .updateCommutePreferences(favoriteRoute: saved);
        if (message != null && context.mounted) {
          context.showSnackBar(message, isError: true);
        }
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showStopSearchDialog({
    required BuildContext context,
    required String mode,
    required WidgetRef ref,
  }) async {
    final selected = await showModalBottomSheet<TransitStop>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StopSearchSheet(mode: mode),
    );
    if (selected != null && context.mounted) {
      final message = await ref
          .read(settingsControllerProvider.notifier)
          .updateCommutePreferences(
            favoriteStopId: selected.id,
            favoriteStopName: selected.name,
          );
      if (message != null && context.mounted) {
        context.showSnackBar(message, isError: true);
      }
    }
  }

  // ── Bottom-sheet picker ──────────────────────────────────
  Future<void> _showPicker<T>({
    required BuildContext context,
    required String title,
    required T current,
    required List<T> items,
    required String Function(T) labelOf,
    required Future<String?> Function(T) onSelect,
  }) async {
    final dark = context.isDarkMode;
    final wrappedItems = [
      for (int i = 0; i < items.length; i++)
        _PickerItem(index: i, value: items[i]),
    ];
    final currentIndex = items.indexOf(current);

    final selected = await showModalBottomSheet<_PickerItem<T>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return MqBottomSheet(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    bottom: MqSpacing.space4,
                  ),
                  child: Text(
                    title,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: dark
                          ? MqColors.contentPrimaryDark
                          : MqColors.contentPrimary,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: wrappedItems.length,
                    itemBuilder: (ctx, i) {
                      final wrapped = wrappedItems[i];
                      final isSelected = wrapped.index == currentIndex;
                      return Semantics(
                        label: labelOf(wrapped.value),
                        selected: isSelected,
                        child: ListTile(
                          title: Text(
                            labelOf(wrapped.value),
                            style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? MqColors.red
                                  : dark
                                  ? MqColors.contentPrimaryDark
                                  : MqColors.contentPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: MqColors.red,
                                  size: 20,
                                )
                              : null,
                          onTap: () => Navigator.pop(ctx, wrapped),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && context.mounted) {
      final message = await onSelect(selected.value);
      if (message != null && context.mounted) {
        context.showSnackBar(message, isError: true);
      }
    }
  }

  // ── Locale codes ──────────────────────────────────────────
  static const List<String?> _localeCodes = [
    null,
    'en',
    'ar',
    'bn',
    'cs',
    'da',
    'de',
    'el',
    'es',
    'fa',
    'fi',
    'fr',
    'he',
    'hi',
    'hu',
    'id',
    'it',
    'ja',
    'ko',
    'ms',
    'ne',
    'nl',
    'no',
    'pl',
    'pt',
    'ro',
    'ru',
    'si',
    'sv',
    'ta',
    'th',
    'tr',
    'uk',
    'ur',
    'vi',
    'zh',
  ];

  static String _preferredStopLabel(
    UserPreferences preferences,
    AppLocalizations l10n,
  ) {
    final stopName = preferences.favoriteStopName.trim();
    if (stopName.isNotEmpty) {
      return stopName;
    }

    final stopId = preferences.favoriteStopId.trim();
    if (stopId.isNotEmpty) {
      return l10n.favoriteStopIdFallback(stopId);
    }

    return l10n.setStopIdPrompt;
  }

  static String _languageLabel(String? code, AppLocalizations l10n) {
    return switch (code) {
      null => l10n.system,
      'en' => 'English',
      'ar' => 'العربية',
      'bn' => 'বাংলা',
      'cs' => 'Čeština',
      'da' => 'Dansk',
      'de' => 'Deutsch',
      'el' => 'Ελληνικά',
      'es' => 'Español',
      'fa' => 'فارسی',
      'fi' => 'Suomi',
      'fr' => 'Français',
      'he' => 'עברית',
      'hi' => 'हिन्दी',
      'hu' => 'Magyar',
      'id' => 'Bahasa Indonesia',
      'it' => 'Italiano',
      'ja' => '日本語',
      'ko' => '한국어',
      'ms' => 'Bahasa Melayu',
      'ne' => 'नेपाली',
      'nl' => 'Nederlands',
      'no' => 'Norsk',
      'pl' => 'Polski',
      'pt' => 'Português',
      'ro' => 'Română',
      'ru' => 'Русский',
      'si' => 'සිංහල',
      'sv' => 'Svenska',
      'ta' => 'தமிழ்',
      'th' => 'ไทย',
      'tr' => 'Türkçe',
      'uk' => 'Українська',
      'ur' => 'اردو',
      'vi' => 'Tiếng Việt',
      'zh' => '中文',
      _ => code.toUpperCase(),
    };
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Private helpers
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Wraps a picker value with its index so that null-valued items
/// (like "System" locale) don't collide with a dismissal.
class _PickerItem<T> {
  const _PickerItem({required this.index, required this.value});
  final int index;
  final T value;
}

class _StopSearchSheet extends ConsumerStatefulWidget {
  const _StopSearchSheet({required this.mode});

  @override
  ConsumerState<_StopSearchSheet> createState() => _StopSearchSheetState();

  final String mode;
}

class _StopSearchSheetState extends ConsumerState<_StopSearchSheet> {
  late final TextEditingController _controller;
  String _query = '';

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
    final dark = context.isDarkMode;
    final trimmedQuery = _query.trim();
    final searchResults = ref.watch(
      tfnswStopSearchProvider((mode: widget.mode, query: trimmedQuery)),
    );

    return MqBottomSheet(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.favoriteStopIdTitle,
              style: context.textTheme.titleMedium?.copyWith(
                color: dark
                    ? MqColors.contentPrimaryDark
                    : MqColors.contentPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: MqSpacing.space4),
            MqInput(
              controller: _controller,
              hint: l10n.favoriteStopIdHint,
              label: l10n.favoriteStopSearchLabel,
              prefixIcon: Icons.search_rounded,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: MqSpacing.space4),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: trimmedQuery.length < 2
                    ? _StopSearchMessage(text: l10n.favoriteStopSearchPrompt)
                    : searchResults.when(
                        data: (stops) {
                          if (stops.isEmpty) {
                            return _StopSearchMessage(
                              text: l10n.favoriteStopSearchEmpty,
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: stops.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final stop = stops[index];
                              return ListTile(
                                leading: Icon(
                                  _stopIcon(widget.mode),
                                  color: MqColors.red,
                                ),
                                title: Text(
                                  stop.name,
                                  style: context.textTheme.titleSmall?.copyWith(
                                    color: dark
                                        ? MqColors.contentPrimaryDark
                                        : MqColors.contentPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  stop.id,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: dark
                                        ? MqColors.contentSecondaryDark
                                        : MqColors.contentSecondary,
                                  ),
                                ),
                                onTap: () => Navigator.pop(context, stop),
                              );
                            },
                          );
                        },
                        error: (_, _) => _StopSearchMessage(
                          text: l10n.favoriteStopSearchError,
                        ),
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: MqColors.red),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: MqSpacing.space3),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    const TransitStop(id: '', name: ''),
                  ),
                  child: Text(
                    l10n.clearPreferredStop,
                    style: const TextStyle(color: MqColors.red),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(
                      color: dark
                          ? MqColors.contentSecondaryDark
                          : MqColors.contentSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static IconData _stopIcon(String mode) {
    return switch (mode) {
      'bus' => Icons.directions_bus_rounded,
      'train' => Icons.train_rounded,
      'metro' => Icons.directions_subway_rounded,
      _ => Icons.location_on_rounded,
    };
  }
}

class _StopSearchMessage extends StatelessWidget {
  const _StopSearchMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.textTheme.bodyMedium?.copyWith(
          color: MqColors.contentSecondary,
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Private widgets
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Uppercase red section header with wide letter spacing.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: MqSpacing.space2,
        bottom: MqSpacing.space3,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 15 * (1 - value)),
              child: child,
            ),
          );
        },
        child: KineticHeader(title: title),
      ),
    );
  }
}

class KineticHeader extends StatelessWidget {
  const KineticHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: context.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: MqColors.red,
      ),
    );
  }
}

class _DangerZoneCard extends StatelessWidget {
  const _DangerZoneCard({
    required this.hapticsEnabled,
    required this.onTap,
    required this.subtitle,
    required this.title,
  });

  final bool hapticsEnabled;
  final VoidCallback onTap;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: MqTactileButton(
        hapticsEnabled: hapticsEnabled,
        onTap: onTap,
        borderRadius: MqSpacing.radiusXl,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsetsDirectional.all(MqSpacing.space6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [MqColors.red, MqColors.red],
            ),
            borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
            border: Border.all(color: MqColors.red),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: MqSpacing.iconLg,
              ),
              const SizedBox(width: MqSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: MqSpacing.space1),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Charcoal card container with subtle border, matching the reference.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? MqColors.charcoal850 : Colors.white,
        borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
        border: Border.all(
          color: dark ? Colors.white.withAlpha(13) : MqColors.sand200,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: dark ? Colors.white.withAlpha(13) : MqColors.sand200,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Row with icon + label on left, current value + chevron on right.
/// Taps open a bottom-sheet picker.
class _TapRow extends StatelessWidget {
  const _TapRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.semanticLabel,
    this.hapticsEnabled = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final String? semanticLabel;
  final bool hapticsEnabled;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    return Semantics(
      label: semanticLabel,
      button: true,
      child: MqTactileButton(
        hapticsEnabled: hapticsEnabled,
        onTap: onTap,
        child: ColoredBox(
          color: dark ? MqColors.charcoal850 : Colors.white,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: MqSpacing.space4,
              vertical: MqSpacing.space4,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: dark ? MqColors.slate500 : MqColors.red,
                ),
                const SizedBox(width: MqSpacing.space4),
                Expanded(
                  child: Text(
                    label,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: dark
                          ? MqColors.contentPrimaryDark
                          : MqColors.contentPrimary,
                    ),
                  ),
                ),
                if (value.isNotEmpty) ...[
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: dark
                            ? MqColors.slate500
                            : MqColors.contentPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: MqSpacing.space1),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: dark ? MqColors.slate500 : MqColors.red,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Row with icon + label on left, custom toggle switch on right.
/// Entire row is tappable to toggle.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.hapticsEnabled = true,
  });

  final IconData icon;
  final String label;
  final bool value;
  final void Function(bool) onChanged;
  final String? semanticLabel;
  final bool hapticsEnabled;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    return Semantics(
      label: semanticLabel,
      toggled: value,
      child: MqTactileButton(
        hapticsEnabled: hapticsEnabled,
        onTap: () => onChanged(!value),
        child: ColoredBox(
          color: dark ? MqColors.charcoal850 : Colors.white,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: MqSpacing.space4,
              vertical: MqSpacing.space4,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: dark ? MqColors.slate500 : MqColors.red,
                ),
                const SizedBox(width: MqSpacing.space4),
                Expanded(
                  child: Text(
                    label,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: dark
                          ? MqColors.contentPrimaryDark
                          : MqColors.contentPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: MqSpacing.minTapTarget,
                  height: MqSpacing.space6,
                  child: Switch.adaptive(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: Colors.white,
                    activeTrackColor: MqColors.red,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: dark
                        ? Colors.white.withAlpha(26)
                        : MqColors.red.withAlpha(48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only info row with icon, title, and subtitle.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    return Semantics(
      label: '$label, $subtitle',
      child: Padding(
        padding: const EdgeInsetsDirectional.all(MqSpacing.space4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 22,
              color: dark ? MqColors.slate500 : MqColors.red,
            ),
            const SizedBox(width: MqSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: dark
                          ? MqColors.contentPrimaryDark
                          : MqColors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: MqSpacing.space1),
                  Text(
                    subtitle,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: dark ? MqColors.slate500 : MqColors.contentPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact summary tile that sits at the top of the Commute Preferences
/// section. Exists primarily so the user understands that the preferences
/// below aren't cosmetic — they directly drive the Metro Countdown card
/// on the Home screen.
class _CommutePreviewTile extends StatelessWidget {
  const _CommutePreviewTile({
    required this.mode,
    required this.route,
    required this.stopId,
    required this.l10n,
  });

  final String mode;
  final String route;
  final String stopId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    final configured = mode != 'none';

    final modeIcon = switch (mode) {
      'metro' => Icons.directions_subway_rounded,
      'bus' => Icons.directions_bus_rounded,
      'train' => Icons.train_rounded,
      _ => Icons.tune_rounded,
    };
    final modeLabel = switch (mode) {
      'metro' => l10n.commuteModeMetro,
      'bus' => l10n.commuteModeBus,
      'train' => l10n.commuteModeTrain,
      _ => l10n.commuteModeNotSet,
    };

    final detailParts = <String>[
      if (route.trim().isNotEmpty) route.trim(),
      if (stopId.trim().isNotEmpty) '#${stopId.trim()}',
    ];
    final detail = detailParts.isEmpty
        ? l10n.setRoutePrompt
        : detailParts.join(' · ');

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: MqSpacing.space3),
      padding: const EdgeInsetsDirectional.all(MqSpacing.space4),
      decoration: BoxDecoration(
        color: dark ? MqColors.red.withAlpha(20) : MqColors.red.withAlpha(14),
        borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
        border: Border.all(
          color: dark ? MqColors.red.withAlpha(70) : MqColors.red.withAlpha(40),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: MqColors.red,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: MqColors.red.withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(modeIcon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: MqSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modeLabel,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: dark
                        ? MqColors.contentPrimaryDark
                        : MqColors.contentPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: configured
                        ? (dark
                              ? Colors.white.withAlpha(200)
                              : MqColors.contentSecondary)
                        : (dark ? MqColors.slate500 : MqColors.charcoal600),
                    fontStyle: configured ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
                const SizedBox(height: MqSpacing.space2),
                Text(
                  l10n.commutePreviewDrivesHomeCountdown,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: MqColors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// About-app hero row with branded red logo container.
class _AboutAppRow extends StatelessWidget {
  const _AboutAppRow({required this.appName, required this.desc});

  final String appName;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    return Semantics(
      label: '$appName, $desc',
      child: Padding(
        padding: const EdgeInsetsDirectional.all(MqSpacing.space4),
        child: Row(
          children: [
            Container(
              width: MqSpacing.space10,
              height: MqSpacing.space10,
              decoration: BoxDecoration(
                color: MqColors.red,
                borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: MqColors.red.withAlpha(51),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: MqSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appName,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: dark
                          ? MqColors.contentPrimaryDark
                          : MqColors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: MqSpacing.space1),
                  Text(
                    desc,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: dark ? MqColors.slate500 : MqColors.charcoal600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
