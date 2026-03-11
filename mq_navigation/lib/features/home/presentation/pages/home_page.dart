import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:mq_navigation/features/profiles/presentation/controllers/profile_controller.dart';
import 'package:mq_navigation/shared/models/academic_models.dart';
import 'package:mq_navigation/shared/widgets/mq_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dashboard = ref.watch(dashboardControllerProvider);
    final profile = ref.watch(profileControllerProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.home),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(dashboardControllerProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh dashboard',
          ),
        ],
      ),
      body: dashboard.when(
        data: (snapshot) {
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(dashboardControllerProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(MqSpacing.space4),
              children: [
                _WelcomeCard(
                  title:
                      '${l10n.welcome}, ${profile?.displayName ?? 'Student'}',
                  subtitle:
                      'Your next priorities, academic signals, and campus schedule are all in one place.',
                ),
                const SizedBox(height: MqSpacing.space4),
                _StressCard(stress: snapshot.stress),
                const SizedBox(height: MqSpacing.space4),
                _XpCard(gamification: snapshot.gamification),
                const SizedBox(height: MqSpacing.space4),
                _SectionHeader(
                  title: 'Upcoming deadlines',
                  actionLabel: l10n.calendar,
                  onPressed: () => context.goNamed(RouteNames.calendar),
                ),
                ...snapshot.upcomingDeadlines.map(
                  (item) => _AcademicItemCard(
                    icon: item.isExam
                        ? Icons.quiz_outlined
                        : Icons.assignment_outlined,
                    title: item.title,
                    subtitle:
                        '${item.unitCode} • ${DateFormat('EEE d MMM, h:mm a').format(item.dueDate)}',
                    trailing: item.priority.toUpperCase(),
                  ),
                ),
                if (snapshot.upcomingDeadlines.isEmpty)
                  const _EmptyStateCard(message: 'No upcoming deadlines.'),
                const SizedBox(height: MqSpacing.space4),
                const _SectionHeader(title: 'Upcoming events'),
                ...snapshot.upcomingEvents.map(
                  (item) => _AcademicItemCard(
                    icon: Icons.event_outlined,
                    title: item.title,
                    subtitle:
                        '${DateFormat('EEE d MMM, h:mm a').format(item.startAt)} • ${item.location ?? item.category}',
                  ),
                ),
                if (snapshot.upcomingEvents.isEmpty)
                  const _EmptyStateCard(message: 'No upcoming events.'),
                const SizedBox(height: MqSpacing.space4),
                const _SectionHeader(title: 'Units'),
                ...snapshot.units
                    .take(4)
                    .map(
                      (item) => _AcademicItemCard(
                        icon: Icons.menu_book_outlined,
                        title: item.code,
                        subtitle: item.name,
                        trailing: item.locationName,
                      ),
                    ),
                if (snapshot.units.isEmpty)
                  const _EmptyStateCard(message: 'No units available yet.'),
                const SizedBox(height: MqSpacing.space4),
                const _SectionHeader(title: 'Open tasks'),
                ...snapshot.openTodos.map(
                  (item) => _AcademicItemCard(
                    icon: item.completed
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    title: item.title,
                    subtitle: item.dueDate == null
                        ? 'No due date'
                        : DateFormat('EEE d MMM').format(item.dueDate!),
                    trailing: item.priority.toUpperCase(),
                  ),
                ),
                if (snapshot.openTodos.isEmpty)
                  const _EmptyStateCard(message: 'No open to-do items.'),
              ],
            ),
          );
        },
        error: (error, stackTrace) => const Center(
          child: Padding(
            padding: EdgeInsets.all(MqSpacing.space4),
            child: Text('Unable to load the dashboard right now.'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return MqCard(
      child: Padding(
        padding: const EdgeInsets.all(MqSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: MqSpacing.space2),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _StressCard extends StatelessWidget {
  const _StressCard({required this.stress});

  final StressSnapshot stress;

  @override
  Widget build(BuildContext context) {
    return MqCard(
      child: Padding(
        padding: const EdgeInsets.all(MqSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stress metrics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: MqSpacing.space2),
            Text(
              '${stress.label} • ${stress.score}/100',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: MqSpacing.space2),
            LinearProgressIndicator(value: stress.score / 100),
            const SizedBox(height: MqSpacing.space3),
            Text(stress.summary),
          ],
        ),
      ),
    );
  }
}

class _XpCard extends StatelessWidget {
  const _XpCard({required this.gamification});

  final GamificationProfile gamification;

  @override
  Widget build(BuildContext context) {
    return MqCard(
      child: Padding(
        padding: const EdgeInsets.all(MqSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gamification', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: MqSpacing.space2),
            Text(
              'Level ${gamification.level} • ${gamification.xp} XP',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: MqSpacing.space2),
            Text(
              '${gamification.streakDays} day streak • best ${gamification.longestStreak} days',
            ),
            const SizedBox(height: MqSpacing.space3),
            LinearProgressIndicator(value: gamification.progressToNextLevel),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onPressed});

  final String title;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MqSpacing.space1),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onPressed, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _AcademicItemCard extends StatelessWidget {
  const _AcademicItemCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return MqCard(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing == null
            ? null
            : Text(trailing!, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MqCard(
      child: Padding(
        padding: const EdgeInsets.all(MqSpacing.space4),
        child: Text(message),
      ),
    );
  }
}
