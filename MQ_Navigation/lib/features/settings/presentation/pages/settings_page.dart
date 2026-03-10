import 'package:flutter/material.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';

/// Settings page — placeholder shell, full implementation in Phase 2.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(MqSpacing.space4),
        children: [
          _SettingsSection(
            title: 'General',
            children: [
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Language'),
                subtitle: const Text('English'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Appearance'),
                subtitle: const Text('System default'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
          _SettingsSection(
            title: 'Security',
            children: [
              ListTile(
                leading: const Icon(Icons.fingerprint_outlined),
                title: const Text('Biometric Lock'),
                subtitle: const Text('Off'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Two-Factor Authentication'),
                subtitle: const Text('Not enrolled'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
          _SettingsSection(
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About MQ Navigation'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MqSpacing.space4,
            MqSpacing.space4,
            MqSpacing.space4,
            MqSpacing.space2,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}
