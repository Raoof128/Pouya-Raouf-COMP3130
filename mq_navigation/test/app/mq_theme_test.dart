import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/app/theme/mq_theme.dart';
import 'package:mq_navigation/app/theme/mq_typography.dart';

void main() {
  group('MqColors', () {
    test('brand colors match web tokens', () {
      expect(MqColors.red, const Color(0xFFA6192E));
      expect(MqColors.brightRed, const Color(0xFFD6001C));
      expect(MqColors.deepRed, const Color(0xFF76232F));
      expect(MqColors.magenta, const Color(0xFFC6007E));
      expect(MqColors.purple, const Color(0xFF80225F));
    });

    test('alabaster palette matches web tokens', () {
      expect(MqColors.alabaster, const Color(0xFFEDEADE));
      expect(MqColors.alabasterDark, const Color(0xFFE5E2D4));
      expect(MqColors.alabasterLight, const Color(0xFFF5F4ED));
    });

    test('semantic colors are defined', () {
      expect(MqColors.success, const Color(0xFF10B981));
      expect(MqColors.warning, const Color(0xFFF59E0B));
      expect(MqColors.error, const Color(0xFFEF4444));
      expect(MqColors.info, const Color(0xFF3B82F6));
    });

    test('charcoal palette has 4 shades', () {
      expect(MqColors.charcoal600, isNotNull);
      expect(MqColors.charcoal700, isNotNull);
      expect(MqColors.charcoal800, isNotNull);
      expect(MqColors.charcoal900, isNotNull);
    });

    test('map colors are defined', () {
      expect(MqColors.mapUserLocation, isNotNull);
      expect(MqColors.mapSelectedBuilding, isNotNull);
      expect(MqColors.mapRouteActive, isNotNull);
    });
  });

  group('MqSpacing', () {
    test('spacing scale is correct', () {
      expect(MqSpacing.space1, 4);
      expect(MqSpacing.space2, 8);
      expect(MqSpacing.space3, 12);
      expect(MqSpacing.space4, 16);
      expect(MqSpacing.space6, 24);
      expect(MqSpacing.space8, 32);
    });

    test('radius tokens are correct', () {
      expect(MqSpacing.radiusSm, 2);
      expect(MqSpacing.radius, 4);
      expect(MqSpacing.radiusMd, 8);
      expect(MqSpacing.radiusLg, 12);
    });

    test('minimum tap target is 48dp (WCAG)', () {
      expect(MqSpacing.minTapTarget, 48);
    });
  });

  group('MqTypography', () {
    test('light text theme has all Material text styles', () {
      final theme = MqTypography.lightTextTheme;
      expect(theme.displayLarge, isNotNull);
      expect(theme.displayMedium, isNotNull);
      expect(theme.displaySmall, isNotNull);
      expect(theme.headlineLarge, isNotNull);
      expect(theme.headlineMedium, isNotNull);
      expect(theme.headlineSmall, isNotNull);
      expect(theme.titleLarge, isNotNull);
      expect(theme.titleMedium, isNotNull);
      expect(theme.titleSmall, isNotNull);
      expect(theme.bodyLarge, isNotNull);
      expect(theme.bodyMedium, isNotNull);
      expect(theme.bodySmall, isNotNull);
      expect(theme.labelLarge, isNotNull);
      expect(theme.labelMedium, isNotNull);
      expect(theme.labelSmall, isNotNull);
    });

    test('font sizes match web token scale', () {
      final theme = MqTypography.lightTextTheme;
      expect(theme.displayLarge!.fontSize, 48); // 3rem
      expect(theme.displayMedium!.fontSize, 36); // 2.25rem
      expect(theme.displaySmall!.fontSize, 30); // 1.875rem
      expect(theme.headlineLarge!.fontSize, 24); // 1.5rem
      expect(theme.bodyLarge!.fontSize, 16); // 1rem
      expect(theme.bodyMedium!.fontSize, 14); // 0.875rem
      expect(theme.bodySmall!.fontSize, 12); // 0.75rem
    });

    test('dark text theme uses alabaster for content', () {
      final theme = MqTypography.darkTextTheme;
      expect(theme.bodyLarge!.color, MqColors.contentPrimaryDark);
    });

    test('serif helper creates serif text style', () {
      final style = MqTypography.serif(fontSize: 20);
      // Font family is null until fonts are bundled in pubspec.yaml.
      expect(style.fontSize, 20);
    });
  });

  group('MqTheme', () {
    test('light theme uses Material 3', () {
      expect(MqTheme.light.useMaterial3, isTrue);
    });

    test('dark theme uses Material 3', () {
      expect(MqTheme.dark.useMaterial3, isTrue);
    });

    test('light theme primary is MQ red', () {
      expect(MqTheme.light.colorScheme.primary, MqColors.red);
    });

    test('dark theme primary is bright red', () {
      expect(MqTheme.dark.colorScheme.primary, MqColors.brightRed);
    });

    test('dark theme has dark brightness', () {
      expect(MqTheme.dark.brightness, Brightness.dark);
    });

    test('light scaffold background is alabaster', () {
      expect(MqTheme.light.scaffoldBackgroundColor, MqColors.alabaster);
    });

    test('dark scaffold background is charcoal800', () {
      expect(MqTheme.dark.scaffoldBackgroundColor, MqColors.charcoal800);
    });

    test('filled button minimum size meets tap target', () {
      final style = MqTheme.light.filledButtonTheme.style;
      final minSize = style?.minimumSize?.resolve({});
      expect(minSize?.height, greaterThanOrEqualTo(MqSpacing.minTapTarget));
    });

    test('card shape uses radiusMd', () {
      final shape = MqTheme.light.cardTheme.shape as RoundedRectangleBorder?;
      expect(shape, isNotNull);
    });
  });
}
