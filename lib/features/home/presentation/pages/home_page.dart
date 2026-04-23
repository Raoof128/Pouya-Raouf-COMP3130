import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/presentation/controllers/map_controller.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_tactile_button.dart';

/// Home screen for the MQ Navigation app.
///
/// Visual language is locked in 100% parity with [SettingsPage]:
/// * Dual-theme tokens only — light & dark branches for every surface,
///   border and content colour.
/// * Dark mode wears the same red radial glow that sits on top of the
///   Settings page.
/// * Section headers use the Settings "uppercase / letter-spaced / red"
///   treatment.
/// * Cards share the same `charcoal850 / white`, `sand200 / white-13%`
///   border, `radiusXl` rounding as Settings cards.
///
/// The light branch keeps the branded campus photograph plus an ivory
/// veil; the dark branch drops the photo for a charcoal wash so the red
/// glow reads cleanly.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _backgroundAsset = 'assets/images/campus_background.jpg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = context.isDarkMode;
    final hapticsEnabled =
        ref.watch(settingsControllerProvider).value?.hapticsEnabled ?? true;
    return Scaffold(
      backgroundColor: dark ? MqColors.charcoal850 : MqColors.alabaster,
      body: Stack(
        children: [
          if (!dark) const _CampusBackground(asset: _backgroundAsset),
          // Settings-parity red radial glow — dark mode only.
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
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _HomeHeader()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      MqSpacing.space5,
                      MqSpacing.space6,
                      MqSpacing.space5,
                      MqSpacing.space12,
                    ),
                    child: Column(
                      children: [
                        const _HeroSection(),
                        const SizedBox(height: MqSpacing.space8),
                        _QuickAccessSection(
                          hapticsEnabled: hapticsEnabled,
                          onTapCategory: (query) {
                            // Riverpod state is global; AppShell preserves
                            // MapPage so we must update the controller
                            // imperatively before switching tabs.
                            ref
                                .read(mapControllerProvider.notifier)
                                .updateSearchQuery(query);
                            context.goNamed(RouteNames.map);
                          },
                        ),
                      ],
                    ),
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

// -------------------------------------------------------------------------- //
// CAMPUS BACKGROUND (LIGHT-MODE ONLY) //
// -------------------------------------------------------------------------- //

class _CampusBackground extends StatelessWidget {
  const _CampusBackground({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: MqColors.alabaster),
          ),
          // Soft ivory veil — visible campus image but readable cards.
          Container(color: MqColors.alabaster.withValues(alpha: 0.78)),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------------- //
// BRANDED TOP HEADER //
// -------------------------------------------------------------------------- //

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = context.isDarkMode;

    // Matches the Settings card border / divider convention exactly.
    final borderColor = dark ? Colors.white.withAlpha(13) : MqColors.sand200;
    final surfaceColor = dark
        ? MqColors.charcoal850.withValues(alpha: 0.92)
        : MqColors.alabasterLight.withValues(alpha: 0.92);
    final accent = dark ? MqColors.vividRed : MqColors.red;

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: MqSpacing.space4,
        vertical: MqSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.school, color: accent, size: MqSpacing.iconDefault),
          const SizedBox(width: MqSpacing.space2),
          Text(
            l10n.home_brandTitle,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------------- //
// WELCOME + CTA HERO //
// -------------------------------------------------------------------------- //

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = context.isDarkMode;

    final titleColor = dark
        ? MqColors.contentPrimaryDark
        : MqColors.contentPrimary;
    final subtitleColor = dark ? MqColors.slate500 : MqColors.charcoal700;
    final ctaColor = dark ? MqColors.vividRed : MqColors.red;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Text(
            l10n.home_welcomeTitle,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineLarge?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
              color: titleColor,
            ),
          ),
          const SizedBox(height: MqSpacing.space2),
          Text(
            l10n.home_welcomeSubtitle,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(
              color: subtitleColor,
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: MqSpacing.space5),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () => context.goNamed(RouteNames.map),
              style: FilledButton.styleFrom(
                backgroundColor: ctaColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: MqSpacing.space6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.near_me, size: MqSpacing.iconMd),
              label: Text(
                l10n.home_startExploring,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------------- //
// QUICK ACCESS GRID //
// -------------------------------------------------------------------------- //

class _QuickAccessSection extends StatelessWidget {
  const _QuickAccessSection({
    required this.hapticsEnabled,
    required this.onTapCategory,
  });

  final bool hapticsEnabled;
  final void Function(String searchQuery) onTapCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final dark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.home_quickAccess),
        SizedBox(
          height: 280,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BentoHeroCard(
                  hapticsEnabled: hapticsEnabled,
                  icon: Icons.restaurant,
                  isDark: dark,
                  label: l10n.home_foodDrink,
                  onTap: () => onTapCategory('food'),
                ),
              ),
              const SizedBox(width: MqSpacing.space4),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _BentoCompactCard(
                        hapticsEnabled: hapticsEnabled,
                        icon: Icons.local_parking,
                        isDark: dark,
                        label: l10n.home_parking,
                        onTap: () => onTapCategory('parking'),
                      ),
                    ),
                    const SizedBox(height: MqSpacing.space4),
                    Expanded(
                      child: _BentoCompactCard(
                        hapticsEnabled: hapticsEnabled,
                        icon: Icons.event,
                        isDark: dark,
                        label: l10n.events,
                        onTap: () => onTapCategory('events'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MqSpacing.space4),
        _SecondaryQuickRow(
          hapticsEnabled: hapticsEnabled,
          items: [
            _QuickAccessItem(
              icon: Icons.school,
              label: l10n.home_faculty,
              searchQuery: 'faculty',
            ),
            _QuickAccessItem(
              icon: Icons.account_balance,
              label: l10n.home_campusHub,
              searchQuery: 'campus hub',
            ),
            _QuickAccessItem(
              icon: Icons.directions_bus,
              label: l10n.home_transport,
              searchQuery: 'bus',
            ),
            _QuickAccessItem(
              icon: Icons.support_agent,
              label: l10n.home_studentServices,
              searchQuery: 'services',
            ),
          ],
          onTapCategory: onTapCategory,
        ),
      ],
    );
  }
}

class _QuickAccessItem {
  const _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.searchQuery,
  });

  final IconData icon;
  final String label;
  final String searchQuery;
}

/// Uppercase red section header — identical treatment to [SettingsPage].
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
        style: context.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: dark ? MqColors.vividRed : MqColors.brightRed,
        ),
      ),
    );
  }
}

class _BentoCompactCard extends StatelessWidget {
  const _BentoCompactCard({
    required this.hapticsEnabled,
    required this.icon,
    required this.isDark,
    required this.label,
    required this.onTap,
  });

  final bool hapticsEnabled;
  final IconData icon;
  final bool isDark;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: MqTactileButton(
        hapticsEnabled: hapticsEnabled,
        onTap: onTap,
        borderRadius: MqSpacing.radiusXl,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? MqColors.charcoal850
                : Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(13) : MqColors.sand200,
            ),
          ),
          padding: const EdgeInsetsDirectional.all(MqSpacing.space4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isDark ? MqColors.vividRed : MqColors.red,
                size: MqSpacing.iconLg,
              ),
              const SizedBox(height: MqSpacing.space2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? MqColors.contentPrimaryDark
                      : MqColors.contentPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoHeroCard extends StatelessWidget {
  const _BentoHeroCard({
    required this.hapticsEnabled,
    required this.icon,
    required this.isDark,
    required this.label,
    required this.onTap,
  });

  final bool hapticsEnabled;
  final IconData icon;
  final bool isDark;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelParts = label.split(' & ');
    final heroLabel = labelParts.length > 1
        ? '${labelParts[0]} &\n${labelParts[1]}'
        : label;

    return Semantics(
      button: true,
      label: label,
      child: MqTactileButton(
        hapticsEnabled: hapticsEnabled,
        onTap: onTap,
        borderRadius: MqSpacing.radiusXl,
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? MqColors.charcoal850
                : Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(13) : MqColors.sand200,
            ),
          ),
          padding: const EdgeInsetsDirectional.all(MqSpacing.space6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsetsDirectional.all(MqSpacing.space3),
                decoration: BoxDecoration(
                  color: isDark ? MqColors.vividRed : MqColors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: MqSpacing.space4),
              Text(
                heroLabel,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: isDark
                      ? MqColors.contentPrimaryDark
                      : MqColors.contentPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryQuickRow extends StatelessWidget {
  const _SecondaryQuickRow({
    required this.hapticsEnabled,
    required this.items,
    required this.onTapCategory,
  });

  final bool hapticsEnabled;
  final List<_QuickAccessItem> items;
  final void Function(String searchQuery) onTapCategory;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Wrap(
      spacing: MqSpacing.space3,
      runSpacing: MqSpacing.space3,
      children: [
        for (final item in items)
          SizedBox(
            width:
                (context.screenWidth -
                    (MqSpacing.space5 * 2) -
                    MqSpacing.space3) /
                2,
            child: MqTactileButton(
              hapticsEnabled: hapticsEnabled,
              onTap: () => onTapCategory(item.searchQuery),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? MqColors.charcoal850
                      : Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(MqSpacing.radiusLg),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha(13)
                        : MqColors.sand200,
                  ),
                ),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: MqSpacing.space3,
                  vertical: MqSpacing.space3,
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: MqSpacing.iconMd,
                      color: isDark ? MqColors.vividRed : MqColors.red,
                    ),
                    const SizedBox(width: MqSpacing.space2),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? MqColors.contentPrimaryDark
                              : MqColors.contentPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
