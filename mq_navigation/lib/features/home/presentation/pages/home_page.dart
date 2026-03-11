import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/shared/widgets/mq_app_bar.dart';

/// Navigation-focused home screen for the Open Day app.
///
/// Provides quick access to the campus map and key campus categories.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final subtitleColor = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: MqAppBar(title: l10n.appName),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MqSpacing.space4),
          child: Column(
            children: [
              const SizedBox(height: MqSpacing.space6),

              // Logo area
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: MqColors.red,
                  borderRadius: BorderRadius.circular(MqSpacing.radiusFull),
                ),
                child: const Icon(
                  Icons.school,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: MqSpacing.space4),
              Text(
                l10n.welcomeTo(l10n.appName),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: MqSpacing.space2),
              Text(
                l10n.campusMapDesc,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: subtitleColor,
                ),
              ),

              const SizedBox(height: MqSpacing.space8),

              // Primary CTA — Explore Campus
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  icon: const Icon(Icons.map, size: 24),
                  label: Text(
                    l10n.exploreMap,
                    style: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () => context.goNamed(RouteNames.map),
                ),
              ),

              const SizedBox(height: MqSpacing.space8),

              // Quick access grid
              Text(
                l10n.campusNavigation,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: MqSpacing.space3),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: MqSpacing.space3,
                crossAxisSpacing: MqSpacing.space3,
                childAspectRatio: 1.4,
                children: [
                  _QuickAccessCard(
                    icon: Icons.restaurant,
                    label: l10n.food,
                    color: MqColors.warning,
                    searchQuery: 'food',
                  ),
                  _QuickAccessCard(
                    icon: Icons.local_parking,
                    label: l10n.services,
                    color: MqColors.purple,
                    searchQuery: 'parking',
                  ),
                  _QuickAccessCard(
                    icon: Icons.menu_book,
                    label: l10n.study,
                    color: MqColors.info,
                    searchQuery: 'library',
                  ),
                  _QuickAccessCard(
                    icon: Icons.local_hospital,
                    label: l10n.health,
                    color: MqColors.success,
                    searchQuery: 'health',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.searchQuery,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.goNamed(
          RouteNames.map,
          queryParameters: {'q': searchQuery},
        ),
        borderRadius: BorderRadius.circular(MqSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(MqSpacing.space3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: MqSpacing.space2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
