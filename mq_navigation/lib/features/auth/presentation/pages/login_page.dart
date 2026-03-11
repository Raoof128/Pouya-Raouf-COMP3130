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

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final message = await ref
        .read(authActionControllerProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted || message == null) {
      return;
    }
    context.showSnackBar(message, isError: true);
  }

  Future<void> _signInWithGoogle() async {
    final message = await ref
        .read(authActionControllerProvider.notifier)
        .signInWithGoogle();
    if (!mounted || message == null) {
      return;
    }
    context.showSnackBar(message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(authActionControllerProvider).isLoading;

    return AuthScaffold(
      title: 'Welcome to MQ Navigation',
      subtitle:
          'Sign in to manage your Macquarie University workload, events, and campus schedule.',
      footer: TextButton(
        onPressed: isLoading ? null : () => context.goNamed(RouteNames.signup),
        child: Text('${l10n.signUp} instead'),
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
              autofillHints: const [AutofillHints.password],
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
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: isLoading
                    ? null
                    : () => context.goNamed(RouteNames.resetPassword),
                child: Text(l10n.forgotPassword),
              ),
            ),
            MqButton(
              label: l10n.signIn,
              isLoading: isLoading,
              onPressed: _signIn,
            ),
            const SizedBox(height: MqSpacing.space3),
            MqButton(
              label: 'Continue with Google',
              icon: Icons.open_in_new,
              variant: MqButtonVariant.outlined,
              onPressed: isLoading ? null : _signInWithGoogle,
            ),
          ],
        ),
      ),
    );
  }
}
