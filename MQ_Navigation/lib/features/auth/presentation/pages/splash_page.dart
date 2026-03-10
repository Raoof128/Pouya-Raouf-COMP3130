import 'package:flutter/material.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';

/// Shown on launch while the session is being resolved.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MqColors.alabaster,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.school_rounded,
              size: 80,
              color: MqColors.red,
              semanticLabel: 'MQ Navigation logo',
            ),
            const SizedBox(height: MqSpacing.space6),
            Text(
              'MQ Navigation',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: MqColors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: MqSpacing.space8),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: MqColors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
