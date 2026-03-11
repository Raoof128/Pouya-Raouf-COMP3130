import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/auth/presentation/controllers/auth_flow_controller.dart';
import 'package:mq_navigation/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/providers/auth_provider.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';

class VerifyEmailPage extends ConsumerWidget {
  const VerifyEmailPage({super.key, this.email});

  final String? email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentEmail = ref.watch(currentUserProvider)?.email ?? email ?? '';
    final isLoading = ref.watch(authActionControllerProvider).isLoading;

    Future<void> resend() async {
      if (currentEmail.isEmpty) {
        context.showSnackBar(
          'No email address is available to resend.',
          isError: true,
        );
        return;
      }
      final message = await ref
          .read(authActionControllerProvider.notifier)
          .resendVerification(currentEmail);
      if (!context.mounted) {
        return;
      }
      context.showSnackBar(
        message ?? 'Verification email sent again.',
        isError: message != null,
      );
    }

    Future<void> refreshStatus() async {
      final auth = Supabase.instance.client.auth;
      final currentSession = auth.currentSession;
      if (currentSession == null) {
        context.showSnackBar(
          'Open the verification link on this device to complete sign-in first.',
          isError: true,
        );
        return;
      }

      try {
        await auth.refreshSession();
      } on AuthException catch (error) {
        if (!context.mounted) {
          return;
        }
        context.showSnackBar(error.message, isError: true);
        return;
      }

      ref.invalidate(authProvider);
      if (context.mounted) {
        context.goNamed(RouteNames.splash);
      }
    }

    return AuthScaffold(
      title: 'Verify your email',
      subtitle: currentEmail.isEmpty
          ? l10n.verifyEmail
          : 'We sent a verification link to $currentEmail.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Open the message on your device, tap the verification link, and return here when complete.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: MqSpacing.space6),
          MqButton(
            label: 'Refresh verification status',
            isLoading: isLoading,
            onPressed: refreshStatus,
          ),
          const SizedBox(height: MqSpacing.space3),
          MqButton(
            label: 'Resend verification email',
            variant: MqButtonVariant.outlined,
            onPressed: isLoading ? null : resend,
          ),
          const SizedBox(height: MqSpacing.space3),
          MqButton(
            label: l10n.signIn,
            variant: MqButtonVariant.text,
            onPressed: isLoading
                ? null
                : () => context.goNamed(RouteNames.login),
          ),
        ],
      ),
    );
  }
}
