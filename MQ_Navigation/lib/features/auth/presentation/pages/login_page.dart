import 'package:flutter/material.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/shared/widgets/mq_input.dart';

/// Placeholder login page — full implementation in Phase 2.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MqSpacing.space6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.school_rounded,
                size: 64,
                color: MqColors.red,
                semanticLabel: 'MQ Navigation logo',
              ),
              const SizedBox(height: MqSpacing.space4),
              Text(
                'Welcome to MQ Navigation',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MqSpacing.space2),
              Text(
                'Sign in to manage your Macquarie University experience',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MqColors.contentTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MqSpacing.space8),
              const MqInput(
                label: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                autofillHints: [AutofillHints.email],
              ),
              const SizedBox(height: MqSpacing.space4),
              const MqInput(
                label: 'Password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                autofillHints: [AutofillHints.password],
              ),
              const SizedBox(height: MqSpacing.space6),
              FilledButton(
                onPressed: () {
                  // TODO(phase2): Wire up Supabase auth
                },
                child: const Text('Sign In'),
              ),
              const SizedBox(height: MqSpacing.space4),
              OutlinedButton(
                onPressed: () {
                  // TODO(phase2): Navigate to signup
                },
                child: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
