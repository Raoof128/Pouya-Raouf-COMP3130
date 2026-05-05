import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/presentation/controllers/map_controller.dart';
import 'package:mq_navigation/features/open_day/presentation/widgets/open_day_home_card.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_navigation/features/transit/domain/entities/metro_departure.dart';
import 'package:mq_navigation/features/transit/presentation/providers/tfnsw_provider.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/models/user_preferences.dart';
import 'package:mq_navigation/shared/widgets/mq_tactile_button.dart';

/// Home screen for the MQ Navigation app.
///
/// Structure (top → bottom):
///   1. Hero — official MQ shield logo + welcome copy + CTA
///   2. Metro Countdown glanceable card (configurable from Settings)
///   3. Quick Access — 2 featured tiles + 3 supporting tiles
///
/// Removed intentionally:
///   - The dedicated top app-bar / branded header. The hero now carries
///     the brand identity via the official MQ shield logo, eliminating
///     vertical clutter and the prior "icon + wordmark" duplication.
///   - "Transport" Quick Access item — the Metro Countdown card already
///     covers the same intent in a more glanceable form.
///   - "Next Class" card and "Events" tile — outside the navigation scope.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _backgroundAsset = 'assets/images/campus_background.jpg';
  static const _logoAsset = 'assets/images/mq_logo.png';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = context.isDarkMode;
    final preferences =
        ref.watch(settingsControllerProvider).value ?? const UserPreferences();
    final hapticsEnabled = preferences.hapticsEnabled;
    final metroDepartures = ref.watch(tfnswMetroProvider);

    return Scaffold(
      backgroundColor: dark ? MqColors.charcoal850 : MqColors.alabaster,
      body: Stack(
        children: [
          _CampusBackground(asset: _backgroundAsset, isDark: dark),
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
                      colors: [MqColors.red.withAlpha(38), Colors.transparent],
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      MqSpacing.space5,
                      MqSpacing.space8,
                      MqSpacing.space5,
                      MqSpacing.space12,
                    ),
                    child: Column(
                      children: [
                        const _HeroSection(logoAsset: _logoAsset),
                        const SizedBox(height: MqSpacing.space8),
                        _MetroCountdownCard(
                          commuteMode: preferences.commuteMode,
                          favoriteRoute: preferences.favoriteRoute,
                          metroDepartures: metroDepartures,
                          onConfigureTap: () =>
                              context.goNamed(RouteNames.settings),
                          onRefreshTap: () =>
                              ref.invalidate(tfnswMetroProvider),
                        ),
                        const SizedBox(height: MqSpacing.space4),
                        // Open Day enhancement — hides itself when the
                        // dataset isn't loaded, morphs between onboarding
                        // and preview based on whether a bachelor is set.
                        const OpenDayHomeCard(),
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
// METRO COUNTDOWN CARD                                                       //
// -------------------------------------------------------------------------- //

/// Compact, glanceable card showing the next departure for the user's
/// configured commute line. If no commute has been set up yet, the card
/// shows a friendly "Set up your commute" CTA that routes to Settings.
class _MetroCountdownCard extends StatelessWidget {
  const _MetroCountdownCard({
    required this.commuteMode,
    required this.favoriteRoute,
    required this.metroDepartures,
    required this.onConfigureTap,
    required this.onRefreshTap,
  });

  final String commuteMode;
  final String favoriteRoute;
  final AsyncValue<List<MetroDeparture>> metroDepartures;
  final VoidCallback onConfigureTap;
  final VoidCallback onRefreshTap;

  bool get _isConfigured => commuteMode != 'none';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = context.isDarkMode;

    final surface = dark
        ? MqColors.charcoal850
        : Colors.white.withValues(alpha: 0.88);
    final border = dark ? Colors.white.withAlpha(13) : MqColors.sand200;
    const accent = MqColors.red;
    final titleColor = dark
        ? MqColors.contentPrimaryDark
        : MqColors.contentPrimary;
    final subtitleColor = dark
        ? MqColors.contentSecondaryDark
        : MqColors.contentSecondary;

    final modeIcon = switch (commuteMode) {
      'metro' => Icons.directions_subway,
      'bus' => Icons.directions_bus,
      'train' => Icons.directions_train,
      _ => Icons.directions_transit_outlined,
    };
    final modeLabel = switch (commuteMode) {
      'metro' => l10n.commuteModeMetro,
      'bus' => l10n.commuteModeBus,
      'train' => l10n.commuteModeTrain,
      _ => l10n.commuteModeNotSet,
    };

    Widget content;
    if (!_isConfigured) {
      content = _EmptyState(
        accent: accent,
        subtitleColor: subtitleColor,
        titleColor: titleColor,
      );
    } else {
      content = metroDepartures.when(
        data: (list) => _DepartureBody(
          accent: accent,
          favoriteRoute: favoriteRoute,
          modeIcon: modeIcon,
          modeLabel: modeLabel,
          departures: list,
          subtitleColor: subtitleColor,
          titleColor: titleColor,
        ),
        loading: () => _LoadingBody(subtitleColor: subtitleColor),
        error: (_, _) => _ErrorBody(subtitleColor: subtitleColor),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsetsDirectional.all(MqSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: dark ? 0.22 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(modeIcon, color: accent, size: 22),
          ),
          const SizedBox(width: MqSpacing.space3),
          Expanded(child: content),
          _MetroCardIconButton(
            icon: Icons.refresh_rounded,
            semanticLabel: l10n.refreshDepartures,
            onTap: onRefreshTap,
          ),
          _MetroCardIconButton(
            icon: Icons.tune_rounded,
            semanticLabel: l10n.configureCommute,
            onTap: onConfigureTap,
          ),
        ],
      ),
    );
  }
}

class _MetroCardIconButton extends StatelessWidget {
  const _MetroCardIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    return IconButton(
      icon: Icon(icon),
      color: dark ? Colors.white54 : MqColors.contentTertiary,
      iconSize: 20,
      onPressed: onTap,
      tooltip: semanticLabel,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.accent,
    required this.subtitleColor,
    required this.titleColor,
  });

  final Color accent;
  final Color subtitleColor;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.homeNextMetroLabel,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: MqSpacing.space1),
        Text(
          l10n.commuteModeNotSet,
          style: context.textTheme.bodySmall?.copyWith(color: subtitleColor),
        ),
      ],
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.subtitleColor});

  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: subtitleColor,
          ),
        ),
        const SizedBox(width: MqSpacing.space2),
        Text(
          l10n.loading,
          style: context.textTheme.bodySmall?.copyWith(color: subtitleColor),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.subtitleColor});

  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Text(
      l10n.homeNextMetroEmpty,
      style: context.textTheme.bodySmall?.copyWith(color: subtitleColor),
    );
  }
}

class _DepartureBody extends StatelessWidget {
  const _DepartureBody({
    required this.accent,
    required this.favoriteRoute,
    required this.modeIcon,
    required this.modeLabel,
    required this.departures,
    required this.subtitleColor,
    required this.titleColor,
  });

  final Color accent;
  final String favoriteRoute;
  final IconData modeIcon;
  final String modeLabel;
  final List<MetroDeparture> departures;
  final Color subtitleColor;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final next = departures.isEmpty ? null : departures.first;
    final routeSuffix = favoriteRoute.trim().isEmpty ? '' : ' • $favoriteRoute';

    final title = next == null
        ? l10n.homeNextMetroLabel
        : l10n.minutesShort(next.minutesUntilDeparture);
    final subtitle = next == null
        ? l10n.homeNextMetroEmpty
        : '${next.destination}$routeSuffix';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              '$modeLabel  ·  ',
              style: context.textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            Flexible(
              child: Text(
                next == null ? '—' : l10n.homeNextMetroLabel,
                style: context.textTheme.labelSmall?.copyWith(
                  color: subtitleColor,
                  letterSpacing: 0.6,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: titleColor,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(color: subtitleColor),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------------------- //
// CAMPUS BACKGROUND                                                          //
// -------------------------------------------------------------------------- //

class _CampusBackground extends StatelessWidget {
  const _CampusBackground({required this.asset, required this.isDark});

  final String asset;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: MqColors.alabaster),
          ),
          Container(
            color: isDark
                ? MqColors.charcoal950.withValues(alpha: 0.42)
                : MqColors.alabaster.withValues(alpha: 0.50),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------------- //
// WELCOME + CTA HERO                                                         //
// -------------------------------------------------------------------------- //

/// Hero block. Lays out the official MQ shield logo to the left of the
/// welcome copy so the brand identity travels with the message — replacing
/// the prior top branding bar — while the CTA button remains full-width
/// below for one-handed reachability.
class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.logoAsset});

  final String logoAsset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = context.isDarkMode;

    final titleColor = dark
        ? MqColors.contentPrimaryDark
        : MqColors.contentPrimary;
    final subtitleColor = dark
        ? MqColors.contentPrimaryDark.withValues(alpha: 0.92)
        : MqColors.contentPrimary.withValues(alpha: 0.92);
    const ctaColor = MqColors.red;
    final heroTextShadow = [
      Shadow(
        blurRadius: 16,
        color: MqColors.black.withValues(alpha: dark ? 0.36 : 0.24),
        offset: const Offset(0, 2),
      ),
    ];

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
          // Logo + welcome copy. The logo is sized to span the full
          // height of the two-line text block so the brand mark feels
          // like a true hero anchor — not an afterthought icon.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Aspect-ratio-aware: the shield asset is taller than wide,
                // so we let height drive layout and let width fall out
                // naturally via `BoxFit.contain`. 100px gives the logo
                // visual mass equal to title + subtitle stacked.
                _MqShieldLogo(asset: logoAsset, size: 100),
                const SizedBox(width: MqSpacing.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.home_welcomeTitle,
                        style: context.textTheme.headlineLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.4,
                          color: titleColor,
                          shadows: heroTextShadow,
                        ),
                      ),
                      const SizedBox(height: MqSpacing.space1),
                      Text(
                        l10n.home_welcomeSubtitle,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: subtitleColor,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          shadows: heroTextShadow,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MqSpacing.space5),
          SizedBox(
            width: double.infinity,
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

/// Renders the official MQ shield logo at a given size, with a graceful
/// fallback shield in case the asset isn't bundled. The fallback keeps
/// the layout stable during initial onboarding of the asset and on any
/// device where the asset failed to load.
class _MqShieldLogo extends StatelessWidget {
  const _MqShieldLogo({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Macquarie University',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => _LogoFallback(size: size),
        ),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    // Pentagon-ish red shield placeholder — preserves visual mass and
    // brand color until the official asset ships.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MqColors.red,
        borderRadius: BorderRadius.circular(size * 0.18),
        boxShadow: [
          BoxShadow(
            color: MqColors.red.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.school_rounded,
          color: Colors.white,
          size: size * 0.55,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------- //
// QUICK ACCESS                                                               //
// -------------------------------------------------------------------------- //

/// Quick Access bento layout, post-Transport removal:
///   Row 1 — two equal featured tiles: Student Services · Faculty
///   Row 2 — three supporting compact tiles: Parking · Campus Hub · Food & Drink
///
/// Transport is intentionally absent — the Metro Countdown card above
/// already covers the same intent in a more glanceable form, so a
/// duplicate Quick Access tile would only add noise.
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
        // Two featured tiles, equal width, equal hierarchy.
        // Each tap dispatches a query that matches a tag we apply
        // in `assets/data/buildings.json` — see that file's tagging
        // convention for the canonical mapping.
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BentoHeroCard(
                  hapticsEnabled: hapticsEnabled,
                  icon: Icons.support_agent,
                  isDark: dark,
                  label: l10n.home_studentServices,
                  onTap: () => onTapCategory('student services'),
                ),
              ),
              const SizedBox(width: MqSpacing.space4),
              Expanded(
                child: _BentoHeroCard(
                  hapticsEnabled: hapticsEnabled,
                  icon: Icons.school,
                  isDark: dark,
                  label: l10n.home_faculty,
                  onTap: () => onTapCategory('faculty'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MqSpacing.space4),
        // Three supporting tiles, lower visual weight.
        _TertiaryQuickRow(
          hapticsEnabled: hapticsEnabled,
          items: [
            _QuickAccessItem(
              icon: Icons.local_parking,
              label: l10n.home_parking,
              searchQuery: 'parking',
            ),
            _QuickAccessItem(
              icon: Icons.account_balance,
              label: l10n.home_campusHub,
              searchQuery: 'campus hub',
            ),
            _QuickAccessItem(
              icon: Icons.restaurant,
              label: l10n.home_foodDrink,
              searchQuery: 'food',
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

/// Prominent section header. Sized + coloured to anchor each section
/// over the photo background.
///
/// Design notes:
///   * **Black, not red.** The prior red-on-photo tint sat in the same
///     hue family as the warm campus image and lost contrast. Pure
///     black/white maximises legibility on every photo crop.
///   * **20pt, weight 800**: a real titleLarge-grade hit, so the eye
///     reads "Quick Access" before any of the tiles below.
///   * **Subtle white halo** on light mode, deep black halo on dark
///     mode: gives the glyphs a bit of separation from a busy photo
///     without looking like a hard outline.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: MqSpacing.space1,
        bottom: MqSpacing.space4,
      ),
      child: Text(
        title.toUpperCase(),
        style: context.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          fontSize: 20,
          height: 1.1,
          color: dark ? Colors.white : MqColors.black,
          shadows: [
            // Soft halo for legibility over the campus photo.
            Shadow(
              blurRadius: 14,
              color: dark
                  ? MqColors.black.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.55),
              offset: const Offset(0, 1),
            ),
            Shadow(
              blurRadius: 4,
              color: dark
                  ? MqColors.black.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.45),
              offset: Offset.zero,
            ),
          ],
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
            // Slightly stronger surface alpha than v7 so the card
            // reads cleanly over high-contrast photo crops, paired
            // with a soft drop shadow for a more premium elevation.
            color: isDark
                ? MqColors.charcoal850.withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : MqColors.black.withValues(alpha: 0.06),
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: MqColors.black.withValues(alpha: isDark ? 0.30 : 0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsetsDirectional.all(MqSpacing.space6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsetsDirectional.all(MqSpacing.space3),
                decoration: const BoxDecoration(
                  color: MqColors.red,
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

/// 3-across compact row — replaces the 4-item wrap grid so the
/// tertiary tiles feel intentional after Events was removed.
class _TertiaryQuickRow extends StatelessWidget {
  const _TertiaryQuickRow({
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
    return IntrinsicHeight(
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i != 0) const SizedBox(width: MqSpacing.space3),
            Expanded(
              child: Semantics(
                button: true,
                label: items[i].label,
                child: MqTactileButton(
                  hapticsEnabled: hapticsEnabled,
                  onTap: () => onTapCategory(items[i].searchQuery),
                  borderRadius: MqSpacing.radiusLg,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? MqColors.charcoal850.withValues(alpha: 0.94)
                          : Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(MqSpacing.radiusLg),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : MqColors.black.withValues(alpha: 0.06),
                        width: 0.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: MqColors.black.withValues(
                            alpha: isDark ? 0.25 : 0.08,
                          ),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: MqSpacing.space3,
                      vertical: MqSpacing.space4,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i].icon,
                          size: MqSpacing.iconMd,
                          color: MqColors.red,
                        ),
                        const SizedBox(height: MqSpacing.space2),
                        Text(
                          items[i].label,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelMedium?.copyWith(
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
              ),
            ),
          ],
        ],
      ),
    );
  }
}
