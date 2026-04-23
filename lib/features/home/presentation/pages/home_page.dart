import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/map/presentation/controllers/map_controller.dart';

/// Home screen for the MQ Navigation app.
///
/// Visual target: warm ivory background layered over a softly faded campus
/// photograph, a branded header, a centred hero section, and a 6-tile
/// Quick Access grid. The bottom navigation lives on [AppShell].
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _backgroundAsset = 'assets/images/campus_background.jpg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: MqColors.alabaster,
      body: Stack(
        children: [
          const _CampusBackground(asset: _backgroundAsset),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _HomeHeader()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MqSpacing.space5,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: MqSpacing.space6),
                        const _HeroSection(),
                        const SizedBox(height: MqSpacing.space8),
                        _QuickAccessSection(
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
                        const SizedBox(height: MqSpacing.space8),
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

// ─────────────────────────────────────────────────────────────
// Campus background with ivory overlay for legibility
// ─────────────────────────────────────────────────────────────

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
            errorBuilder: (_, _, _) => const ColoredBox(
              color: MqColors.alabaster,
            ),
          ),
          // Soft ivory veil — visible campus image but readable cards.
          Container(color: MqColors.alabaster.withValues(alpha: 0.78)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Branded top header
// ─────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MqSpacing.space4,
        vertical: MqSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: MqColors.alabasterLight.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: MqColors.sand200, width: 1),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.school, color: MqColors.red, size: MqSpacing.iconDefault),
          SizedBox(width: MqSpacing.space2),
          Text(
            'MQ NAVIGATION',
            style: TextStyle(
              color: MqColors.red,
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

// ─────────────────────────────────────────────────────────────
// Welcome + CTA hero
// ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Welcome to MQ Navigation',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.5,
            color: MqColors.contentPrimary,
          ),
        ),
        const SizedBox(height: MqSpacing.space3),
        Text(
          'Find your way around campus quickly and easily.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: MqColors.charcoal700,
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
              backgroundColor: MqColors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: MqSpacing.space6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.near_me, size: 20),
            label: const Text(
              'Start Exploring',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Quick Access grid
// ─────────────────────────────────────────────────────────────

class _QuickAccessSection extends StatelessWidget {
  const _QuickAccessSection({required this.onTapCategory});

  final void Function(String searchQuery) onTapCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const items = <_QuickAccessItem>[
      _QuickAccessItem(
        icon: Icons.restaurant,
        label: 'Food & Drink',
        searchQuery: 'food',
      ),
      _QuickAccessItem(
        icon: Icons.local_parking,
        label: 'Parking',
        searchQuery: 'parking',
      ),
      _QuickAccessItem(
        icon: Icons.school,
        label: 'Faculty',
        searchQuery: 'faculty',
      ),
      _QuickAccessItem(
        icon: Icons.account_balance,
        label: 'Campus Hub',
        searchQuery: 'campus hub',
      ),
      _QuickAccessItem(
        icon: Icons.directions_bus,
        label: 'Transport',
        searchQuery: 'bus',
      ),
      _QuickAccessItem(
        icon: Icons.support_agent,
        label: 'Student Services',
        searchQuery: 'services',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: MqColors.contentPrimary,
          ),
        ),
        const SizedBox(height: MqSpacing.space4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: MqSpacing.space4,
            crossAxisSpacing: MqSpacing.space4,
            childAspectRatio: 1.05,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            return _QuickAccessCard(
              icon: item.icon,
              label: item.label,
              onTap: () => onTapCategory(item.searchQuery),
            );
          },
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

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(MqSpacing.radiusXl),
              border: Border.all(
                color: MqColors.sand200.withValues(alpha: 0.8),
              ),
              boxShadow: [
                BoxShadow(
                  color: MqColors.red.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(MqSpacing.space4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDECEE),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: MqColors.red, size: 24),
                ),
                const SizedBox(height: MqSpacing.space3),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: MqColors.contentPrimary,
                    letterSpacing: 0.2,
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
