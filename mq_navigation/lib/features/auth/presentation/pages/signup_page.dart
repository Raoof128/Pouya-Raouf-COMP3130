import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/core/utils/validators.dart';
import 'package:mq_navigation/features/auth/presentation/controllers/auth_flow_controller.dart';
import 'package:mq_navigation/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mq_navigation/shared/extensions/context_extensions.dart';
import 'package:mq_navigation/shared/widgets/mq_button.dart';
import 'package:mq_navigation/shared/widgets/mq_input.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final message = await ref
        .read(authActionControllerProvider.notifier)
        .signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    if (message != null) {
      context.showSnackBar(message, isError: true);
      return;
    }

    context.goNamed(
      RouteNames.verifyEmail,
      queryParameters: {'email': _emailController.text.trim()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(authActionControllerProvider).isLoading;

    return AuthScaffold(
      title: 'Create your account',
      subtitle:
          'Register with your university email, then verify it before continuing.',
      footer: TextButton(
        onPressed: isLoading ? null : () => context.goNamed(RouteNames.login),
        child: Text('${l10n.signIn} instead'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MqInput(
              label: l10n.email,
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
            ),
            const SizedBox(height: MqSpacing.space4),
            MqInput(
              label: l10n.password,
              controller: _passwordController,
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
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
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) =>
                  Validators.confirmation(value, _passwordController.text),
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
              label: l10n.signUp,
              isLoading: isLoading,
              onPressed: _signUp,
            ),
          ],
        ),
      ),
    );
  }
}
