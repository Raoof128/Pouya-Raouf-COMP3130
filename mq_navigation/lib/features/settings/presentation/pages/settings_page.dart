import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/auth/presentation/controllers/auth_flow_controller.dart';
import 'package:mq_navigation/features/profiles/presentation/controllers/profile_controller.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsState = ref.watch(settingsControllerProvider);
    final profile = ref.watch(profileControllerProvider).value;
    final authActionState = ref.watch(authActionControllerProvider);

    Future<void> signOut() async {
      final message = await ref
          .read(authActionControllerProvider.notifier)
          .signOut();
      if (!context.mounted || message == null) {
        return;
      }
      context.showSnackBar(message, isError: true);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: settingsState.when(
        data: (preferences) {
          return ListView(
            padding: const EdgeInsets.all(MqSpacing.space4),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(MqSpacing.space4),
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(profile?.displayName ?? 'Profile'),
                  subtitle: Text(profile?.email ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed(RouteNames.profileEdit),
                ),
              ),
              const SizedBox(height: MqSpacing.space4),
              _SettingsSection(
                title: 'General',
                child: Column(
                  children: [
                    _DropdownListTile<ThemeMode>(
                      icon: Icons.dark_mode_outlined,
                      title: l10n.appearance,
                      value: preferences.themeMode,
                      itemLabel: (value) => switch (value) {
                        ThemeMode.system => l10n.system,
                        ThemeMode.light => l10n.light,
                        ThemeMode.dark => l10n.dark,
                      },
                      items: ThemeMode.values,
                      onChanged: (value) => ref
                          .read(settingsControllerProvider.notifier)
                          .updateThemeMode(value),
                    ),
                    const Divider(height: 1),
                    _DropdownListTile<String?>(
                      icon: Icons.language_outlined,
                      title: l10n.language,
                      value: preferences.localeCode,
                      itemLabel: (value) => switch (value) {
                        null => 'System default',
                        'en' => 'English',
                        'ar' => 'Arabic',
                        'fa' => 'Persian',
                        'zh' => 'Chinese',
                        'hi' => 'Hindi',
                        _ => value.toUpperCase(),
                      },
                      items: const [null, 'en', 'ar', 'fa', 'zh', 'hi'],
                      onChanged: (value) => ref
                          .read(settingsControllerProvider.notifier)
                          .updateLocaleCode(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MqSpacing.space4),
              _SettingsSection(
                title: l10n.notifications,
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined),
                      title: Text(l10n.notifications),
                      value: preferences.notificationsEnabled,
                      onChanged: (value) => ref
                          .read(settingsControllerProvider.notifier)
                          .updateNotificationsEnabled(value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.mail_outline),
                      title: const Text('Email notifications'),
                      value: preferences.emailNotifications,
                      onChanged: (value) => ref
                          .read(settingsControllerProvider.notifier)
                          .updateEmailNotifications(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MqSpacing.space4),
              _SettingsSection(
                title: l10n.security,
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint_outlined),
                      title: const Text('Biometric lock'),
                      value: preferences.biometricLockEnabled,
                      onChanged: (value) async {
                        final message = await ref
                            .read(settingsControllerProvider.notifier)
                            .updateBiometricLockEnabled(value);
                        if (message != null && context.mounted) {
                          context.showSnackBar(message, isError: true);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: const Text('Two-factor authentication'),
                      subtitle: const Text(
                        'Enroll an authenticator app or complete an MFA challenge.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.pushNamed(RouteNames.mfa),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MqSpacing.space4),
              const _SettingsSection(
                title: 'Experience',
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.auto_graph_outlined),
                      title: Text('Stress and workload insights'),
                      subtitle: Text(
                        'Dashboard and calendar use your academic data to surface pressure points.',
                      ),
                    ),
                    Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.workspace_premium_outlined),
                      title: Text('Gamification progress'),
                      subtitle: Text(
                        'XP and streaks are shown on Home from your Supabase profile.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MqSpacing.space4),
              _SettingsSection(
                title: l10n.about,
                child: const Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('MQ Navigation'),
                      subtitle: Text(
                        'Flutter mobile client for Macquarie University.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MqSpacing.space6),
              FilledButton.tonalIcon(
                onPressed: authActionState.isLoading ? null : signOut,
                icon: const Icon(Icons.logout),
                label: Text(l10n.signOut),
              ),
            ],
          );
        },
        error: (error, stackTrace) => const Center(
          child: Padding(
            padding: EdgeInsets.all(MqSpacing.space4),
            child: Text('Unable to load your settings.'),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: MqSpacing.space1,
            bottom: MqSpacing.space2,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(margin: EdgeInsets.zero, child: child),
      ],
    );
  }
}

class _DropdownListTile<T> extends StatelessWidget {
  const _DropdownListTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final Future<String?> Function(T value) onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item)),
              ),
            )
            .toList(),
        onChanged: (item) async {
          if (item == null) {
            return;
          }
          final message = await onChanged(item);
          if (message != null && context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
        },
      ),
    );
  }
}
