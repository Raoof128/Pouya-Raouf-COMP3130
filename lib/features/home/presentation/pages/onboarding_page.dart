import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mq_navigation/app/l10n/generated/app_localizations.dart';
import 'package:mq_navigation/app/router/route_names.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/shared/widgets/mq_tactile_button.dart';
import 'package:mq_navigation/features/settings/presentation/controllers/settings_controller.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _onNext() {
    if (_currentIndex == 2) {
      ref.read(settingsControllerProvider.notifier).completeOnboarding();
      context.goNamed(RouteNames.home);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> pages = [
      {
        'icon': Icons.map_rounded,
        'title': l10n.onboardingMapTitle,
        'body': l10n.onboardingMapBody,
      },
      {
        'icon': Icons.train_rounded,
        'title': l10n.onboardingTransitTitle,
        'body': l10n.onboardingTransitBody,
      },
      {
        'icon': Icons.security_rounded,
        'title': l10n.onboardingPrivacyTitle,
        'body': l10n.onboardingPrivacyBody,
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? MqColors.charcoal850 : MqColors.alabaster,
      body: Stack(
        children: [
          if (isDark)
            PositionedDirectional(
              top: -150,
              start: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      MqColors.vividRed.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      return _buildPageContent(pages[index], isDark);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(pages.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsetsDirectional.only(end: 8),
                            height: 8,
                            width: _currentIndex == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentIndex == index
                                  ? (isDark ? MqColors.vividRed : MqColors.red)
                                  : Colors.grey.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      MqTactileButton(
                        onTap: _onNext,
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? MqColors.vividRed : MqColors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _currentIndex == pages.length - 1
                                ? l10n.onboardingStart
                                : l10n.onboardingNext,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(Map<String, dynamic> page, bool isDark) {
    return Padding(
      padding: const EdgeInsetsDirectional.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.all(24),
            decoration: BoxDecoration(
              color: isDark ? MqColors.charcoal950 : Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Icon(
              page['icon'],
              size: 80,
              color: isDark ? MqColors.vividRed : MqColors.red,
            ),
          ),
          const SizedBox(height: 48),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page['title'],
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  page['body'],
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
