import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/core/utils/validators.dart';
import 'package:mq_navigation/features/auth/presentation/controllers/auth_flow_controller.dart';
import 'package:mq_navigation/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/providers/auth_provider.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';
import 'package:mq_navigation/shared/widgets/mq_input.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, this.forceRecoveryMode = false});

  final bool forceRecoveryMode;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _requestFormKey = GlobalKey<FormState>();
  final _recoveryFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(authActionControllerProvider).isLoading;
    final lastEvent = ref.watch(lastAuthChangeEventProvider);
    final isRecoveryMode =
        widget.forceRecoveryMode ||
        lastEvent == AuthChangeEvent.passwordRecovery;

    Future<void> requestReset() async {
      if (!_requestFormKey.currentState!.validate()) {
        return;
      }
      final message = await ref
          .read(authActionControllerProvider.notifier)
          .sendPasswordReset(_emailController.text);
      if (!context.mounted) {
        return;
      }
      context.showSnackBar(
        message ?? 'Password reset instructions sent.',
        isError: message != null,
      );
    }

    Future<void> updatePassword() async {
      if (!_recoveryFormKey.currentState!.validate()) {
        return;
      }
      final message = await ref
          .read(authActionControllerProvider.notifier)
          .updatePassword(_newPasswordController.text);
      if (!context.mounted) {
        return;
      }
      if (message != null) {
        context.showSnackBar(message, isError: true);
        return;
      }
      ref.invalidate(authProvider);
      context.goNamed(RouteNames.home);
    }

    return AuthScaffold(
      title: l10n.resetPassword,
      subtitle: isRecoveryMode
          ? 'Set a new password for your account.'
          : 'Enter your email to receive a secure password reset link.',
      footer: TextButton(
        onPressed: isLoading ? null : () => context.goNamed(RouteNames.login),
        child: Text(l10n.signIn),
      ),
      child: isRecoveryMode
          ? Form(
              key: _recoveryFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MqInput(
                    label: l10n.password,
                    controller: _newPasswordController,
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    validator: Validators.password,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: MqSpacing.space4),
                  MqInput(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    prefixIcon: Icons.lock_reset_outlined,
                    obscureText: _obscureConfirmation,
                    validator: (value) => Validators.confirmation(
                      value,
                      _newPasswordController.text,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureConfirmation = !_obscureConfirmation;
                        });
                      },
                      icon: Icon(
                        _obscureConfirmation
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: MqSpacing.space6),
                  MqButton(
                    label: l10n.update,
                    isLoading: isLoading,
                    onPressed: updatePassword,
                  ),
                ],
              ),
            )
          : Form(
              key: _requestFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MqInput(
                    label: l10n.email,
                    controller: _emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: MqSpacing.space6),
                  MqButton(
                    label: l10n.resetPassword,
                    isLoading: isLoading,
                    onPressed: requestReset,
                  ),
                ],
              ),
            ),
    );
  }
}
