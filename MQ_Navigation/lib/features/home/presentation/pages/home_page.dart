import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';

/// Navigation-focused home screen for the Open Day app.
///
/// Provides quick access to the campus map and key campus categories.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('MQ Navigation')),
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
                  borderRadius: BorderRadius.circular(MqSpacing.radius3xl),
                ),
                child: const Icon(
                  Icons.school,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: MqSpacing.space4),
              Text(
                'Welcome to\nMacquarie University',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: MqSpacing.space2),
              Text(
                'Find your way around campus',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: MqColors.charcoal600,
                ),
              ),

              const SizedBox(height: MqSpacing.space8),

              // Primary CTA — Explore Campus
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  icon: const Icon(Icons.map, size: 24),
                  label: const Text(
                    'Explore Campus',
                    style: TextStyle(fontSize: 18),
                  ),
                  onPressed: () => context.go('/map'),
                ),
              ),

              const SizedBox(height: MqSpacing.space8),

              // Quick access grid
              Text(
                'Quick Access',
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
                children: const [
                  _QuickAccessCard(
                    icon: Icons.restaurant,
                    label: 'Food & Dining',
                    color: Colors.orange,
                  ),
                  _QuickAccessCard(
                    icon: Icons.local_parking,
                    label: 'Parking',
                    color: Colors.purple,
                  ),
                  _QuickAccessCard(
                    icon: Icons.menu_book,
                    label: 'Library',
                    color: Colors.blue,
                  ),
                  _QuickAccessCard(
                    icon: Icons.local_hospital,
                    label: 'Health',
                    color: Colors.green,
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
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/map'),
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
