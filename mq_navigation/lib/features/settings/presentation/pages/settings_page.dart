import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsState = ref.watch(settingsControllerProvider);
    final dark = context.isDarkMode;

    return Scaffold(
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
                            MqColors.vividRed.withAlpha(38),
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
                      child: Text(
                        l10n.settings,
                        style: context.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: dark
                              ? MqColors.contentPrimaryDark
                              : MqColors.contentPrimary,
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

                    // ── Notifications section ───────────────────
                    _SectionHeader(title: l10n.notifications),
                    _SettingsCard(
                      children: [
                        _ToggleRow(
                          icon: Icons.notifications_outlined,
                          label: l10n.notifications,
                          value: preferences.notificationsEnabled,
                          semanticLabel: l10n.notifications,
                          onChanged: (v) async {
                            final msg = await ref
                                .read(settingsControllerProvider.notifier)
                                .updateNotificationsEnabled(v);
                            if (msg != null && context.mounted) {
                              context.showSnackBar(msg, isError: true);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: MqSpacing.space6),

                    // ── Experience section ───────────────────────
                    _SectionHeader(title: l10n.settings_experience),
                    _SettingsCard(
                      children: [
                        _InfoRow(
                          icon: Icons.map_outlined,
                          label: l10n.campusMapLabel,
                          subtitle: l10n.campusMapDesc,
                        ),
                      ],
                    ),
                    const SizedBox(height: MqSpacing.space6),

                    // ── About section ────────────────────────────
                    _SectionHeader(title: l10n.about),
                    _SettingsCard(
                      children: [
                        _AboutAppRow(
                          appName: l10n.appName,
                          desc: l10n.aboutDesc,
                        ),
                        _InfoRow(
                          icon: Icons.code_outlined,
                          label: l10n.version,
                          subtitle: '1.0.0',
                        ),
                        _InfoRow(
                          icon: Icons.people_outline,
                          label: l10n.about_theTeam,
                          subtitle:
                              'Raouf Abedini & Pouya Alavi\nCOMP3130, Macquarie University',
                        ),
                      ],
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
        loading: () => Center(
          child: CircularProgressIndicator(
            color: context.isDarkMode ? MqColors.vividRed : MqColors.red,
          ),
        ),
      ),
    );
  }

  // ── Bottom-sheet picker ──────────────────────────────────
  // Uses _PickerItem wrapper so null-valued items (e.g. "System" locale)
  // are distinguishable from a dismissal which also returns null.
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
      backgroundColor: dark ? MqColors.charcoal850 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MqSpacing.radiusXl),
        ),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          maxChildSize: 0.75,
          minChildSize: 0.3,
          builder: (ctx, controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: MqSpacing.space3,
                  ),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.white.withAlpha(26)
                          : Colors.black.withAlpha(26),
                      borderRadius: BorderRadius.circular(MqSpacing.radiusFull),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.all(MqSpacing.space4),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: dark
                          ? MqColors.contentPrimaryDark
                          : MqColors.contentPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
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
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? MqColors.vividRed
                                  : dark
                                  ? MqColors.contentPrimaryDark
                                  : MqColors.contentPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: MqColors.vividRed,
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
            );
          },
        );
      },
    );

    if (selected != null && context.mounted) {
      final message = await onSelect(selected.value);
      if (message != null && context.mounted) {
        context.showSnackBar(message);
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Private widgets
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Uppercase red section header with wide letter spacing.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: MqSpacing.space2,
        bottom: MqSpacing.space3,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: dark ? MqColors.vividRed : MqColors.brightRed,
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
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: dark ? Colors.white.withAlpha(13) : MqColors.sand100,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(MqSpacing.space4),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: dark ? MqColors.slate500 : MqColors.charcoal600,
                ),
                const SizedBox(width: MqSpacing.space4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: dark
                          ? MqColors.contentPrimaryDark
                          : MqColors.contentPrimary,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: dark ? MqColors.slate500 : MqColors.charcoal600,
                  ),
                ),
                const SizedBox(width: MqSpacing.space1),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: dark ? MqColors.slate500 : MqColors.charcoal600,
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
  });

  final IconData icon;
  final String label;
  final bool value;
  final void Function(bool) onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    return Semantics(
      label: semanticLabel,
      toggled: value,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          splashColor: dark ? Colors.white.withAlpha(13) : MqColors.sand100,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(MqSpacing.space4),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: dark ? MqColors.slate500 : MqColors.charcoal600,
                ),
                const SizedBox(width: MqSpacing.space4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: dark
                          ? MqColors.contentPrimaryDark
                          : MqColors.contentPrimary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  height: MqSpacing.space6,
                  child: Switch.adaptive(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: Colors.white,
                    activeTrackColor: MqColors.vividRed,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: dark
                        ? Colors.white.withAlpha(26)
                        : MqColors.sand300,
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
              color: dark ? MqColors.slate500 : MqColors.charcoal600,
            ),
            const SizedBox(width: MqSpacing.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: dark
                          ? MqColors.contentPrimaryDark
                          : MqColors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: MqSpacing.space1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
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
                color: MqColors.vividRed,
                borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: MqColors.vividRed.withAlpha(51),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: dark
                          ? MqColors.contentPrimaryDark
                          : MqColors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: MqSpacing.space1),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 13,
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
