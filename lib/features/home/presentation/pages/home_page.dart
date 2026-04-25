import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/presentation/controllers/map_controller.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_navigation/features/transit/domain/entities/metro_departure.dart';
import 'package:mq_navigation/features/transit/presentation/providers/tfnsw_provider.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/models/user_preferences.dart';
import 'package:mq_navigation/shared/widgets/mq_tactile_button.dart';

/// Home screen for the MQ Navigation app.
///
/// Structure (top → bottom):
///   1. Branded header
///   2. Hero (welcome + CTA)
///   3. Metro Countdown glanceable card (configurable from Settings)
///   4. Quick Access bento grid — campus navigation categories only
///
/// Removed intentionally: "Next Class" card (no timetable ingestion) and
/// the "Events" tile from Quick Access — both sit outside the app's
/// navigation-focused scope.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _backgroundAsset = 'assets/images/campus_background.jpg';

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
                        _MetroCountdownCard(
                          commuteMode: preferences.commuteMode,
                          favoriteRoute: preferences.favoriteRoute,
                          metroDepartures: metroDepartures,
                          onConfigureTap: () =>
                              context.goNamed(RouteNames.settings),
                          onRefreshTap: () =>
                              ref.invalidate(tfnswMetroProvider),
                        ),
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
// BRANDED TOP HEADER                                                         //
// -------------------------------------------------------------------------- //

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = context.isDarkMode;

    final borderColor = dark ? Colors.white.withAlpha(13) : MqColors.sand200;
    final surfaceColor = dark
        ? MqColors.charcoal850.withValues(alpha: 0.92)
        : MqColors.alabasterLight.withValues(alpha: 0.92);
    const accent = MqColors.red;

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
          const Icon(Icons.school, color: accent, size: MqSpacing.iconDefault),
          const SizedBox(width: MqSpacing.space2),
          Text(
            l10n.home_brandTitle,
            style: const TextStyle(
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
// WELCOME + CTA HERO                                                         //
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
    final subtitleColor = dark
        ? MqColors.contentPrimaryDark.withValues(alpha: 0.92)
        : MqColors.contentPrimary.withValues(alpha: 0.92);
    const ctaColor = MqColors.red;
    final heroTextShadow = [
      Shadow(
        blurRadius: 16,
        color: Colors.black.withValues(alpha: dark ? 0.36 : 0.24),
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
          Text(
            l10n.home_welcomeTitle,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineLarge?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
              color: titleColor,
              shadows: heroTextShadow,
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
              fontWeight: FontWeight.w500,
              shadows: heroTextShadow,
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
// QUICK ACCESS                                                               //
// -------------------------------------------------------------------------- //

/// Bento layout tuned for balance without Events:
///   Row 1  |  Hero: Student Services  |  Stack: Parking + Campus Hub
///   Row 2  |  3 equal tiles:  Faculty · Food & Drink · Transport
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
                  icon: Icons.support_agent,
                  isDark: dark,
                  label: l10n.home_studentServices,
                  onTap: () => onTapCategory('services'),
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
                        icon: Icons.account_balance,
                        isDark: dark,
                        label: l10n.home_campusHub,
                        onTap: () => onTapCategory('campus hub'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MqSpacing.space4),
        _TertiaryQuickRow(
          hapticsEnabled: hapticsEnabled,
          items: [
            _QuickAccessItem(
              icon: Icons.school,
              label: l10n.home_faculty,
              searchQuery: 'faculty',
            ),
            _QuickAccessItem(
              icon: Icons.restaurant,
              label: l10n.home_foodDrink,
              searchQuery: 'food',
            ),
            _QuickAccessItem(
              icon: Icons.directions_bus,
              label: l10n.home_transport,
              searchQuery: 'bus',
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
      child: Text(
        title.toUpperCase(),
        style: context.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: MqColors.red,
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
              Icon(icon, color: MqColors.red, size: MqSpacing.iconLg),
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
              child: MqTactileButton(
                hapticsEnabled: hapticsEnabled,
                onTap: () => onTapCategory(items[i].searchQuery),
                borderRadius: MqSpacing.radiusLg,
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
          ],
        ],
      ),
    );
  }
}
