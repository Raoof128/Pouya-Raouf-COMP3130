import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/features/auth/presentation/controllers/mfa_controller.dart';
import 'package:mq_navigation/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';
import 'package:mq_navigation/shared/widgets/mq_input.dart';

class MfaPage extends ConsumerStatefulWidget {
  const MfaPage({super.key});

  @override
  ConsumerState<MfaPage> createState() => _MfaPageState();
}

class _MfaPageState extends ConsumerState<MfaPage> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mfaState = ref.watch(mfaControllerProvider);
    final data = mfaState.value;
    final pendingEnrollment = data?.pendingEnrollment;
    final hasVerifiedFactor = data?.hasVerifiedFactor ?? false;

    Future<void> startEnrollment() async {
      final message = await ref
          .read(mfaControllerProvider.notifier)
          .enrollTotp();
      if (!context.mounted || message == null) {
        return;
      }
      context.showSnackBar(message, isError: true);
    }

    Future<void> verifyPendingEnrollment() async {
      final message = await ref
          .read(mfaControllerProvider.notifier)
          .verifyPendingEnrollment(_codeController.text);
      if (!context.mounted) {
        return;
      }
      if (message != null) {
        context.showSnackBar(message, isError: true);
        return;
      }
      context.goNamed(RouteNames.home);
    }

    Future<void> verifyExistingFactor() async {
      final message = await ref
          .read(mfaControllerProvider.notifier)
          .verifyExistingFactor(_codeController.text);
      if (!context.mounted) {
        return;
      }
      if (message != null) {
        context.showSnackBar(message, isError: true);
        return;
      }
      context.goNamed(RouteNames.home);
    }

    Future<void> copySecret() async {
      final secret = pendingEnrollment?.secret;
      if (secret == null || secret.isEmpty) {
        return;
      }
      await Clipboard.setData(ClipboardData(text: secret));
      if (!context.mounted) {
        return;
      }
      context.showSnackBar('Authenticator secret copied.');
    }

    return AuthScaffold(
      title: 'Multi-factor authentication',
      subtitle: hasVerifiedFactor
          ? 'Enter the 6-digit code from your authenticator app.'
          : 'Add a TOTP authenticator to secure your account.',
      child: mfaState.when(
        data: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pendingEnrollment != null) ...[
                Text(
                  'Add the following secret to your authenticator app, then enter the generated code.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: MqSpacing.space4),
                SelectableText(
                  pendingEnrollment.secret,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: MqSpacing.space3),
                MqButton(
                  label: 'Copy secret',
                  variant: MqButtonVariant.outlined,
                  onPressed: copySecret,
                ),
                const SizedBox(height: MqSpacing.space4),
              ],
              if (hasVerifiedFactor || pendingEnrollment != null) ...[
                MqInput(
                  label: 'Authentication code',
                  controller: _codeController,
                  prefixIcon: Icons.security_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: MqSpacing.space6),
                MqButton(
                  label: pendingEnrollment != null
                      ? 'Verify and enable MFA'
                      : 'Verify code',
                  onPressed: pendingEnrollment != null
                      ? verifyPendingEnrollment
                      : verifyExistingFactor,
                ),
              ] else ...[
                Text(
                  'You do not have a verified MFA factor yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: MqSpacing.space6),
                MqButton(
                  label: 'Set up authenticator app',
                  onPressed: startEnrollment,
                ),
              ],
            ],
          );
        },
        error: (error, stackTrace) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'We could not load your MFA state right now.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: MqSpacing.space4),
            MqButton(
              label: 'Retry',
              onPressed: () =>
                  ref.read(mfaControllerProvider.notifier).refresh(),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
