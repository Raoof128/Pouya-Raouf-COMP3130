import 'package:flutter/material.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';
import 'package:mq_navigation/app/theme/mq_spacing.dart';
import 'package:mq_navigation/app/theme/mq_typography.dart';

/// Builds the [ThemeData] for the MQ Navigation app.
abstract final class MqTheme {
  // -- Light theme --
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: MqColors.red,
      primary: MqColors.red,
      onPrimary: Colors.white,
      secondary: MqColors.deepRed,
      onSecondary: Colors.white,
      error: MqColors.error,
      surface: MqColors.alabasterLight,
      onSurface: MqColors.contentPrimary,
      surfaceContainerHighest: MqColors.sand200,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: MqTypography.lightTextTheme,
      scaffoldBackgroundColor: MqColors.alabaster,
      appBarTheme: const AppBarTheme(
        backgroundColor: MqColors.alabaster,
        foregroundColor: MqColors.contentPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: MqColors.alabasterLight,
        indicatorColor: MqColors.red.withAlpha(30),
        elevation: 3,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: MqColors.charcoal600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: MqSpacing.space4,
          vertical: MqSpacing.space2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MqSpacing.space4,
          vertical: MqSpacing.space3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          borderSide: const BorderSide(color: MqColors.sand300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          borderSide: const BorderSide(color: MqColors.sand300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          borderSide: const BorderSide(color: MqColors.red, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          borderSide: const BorderSide(color: MqColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          borderSide: const BorderSide(color: MqColors.error, width: 2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MqColors.red,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: MqColors.red,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, MqSpacing.minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MqColors.red,
          minimumSize: const Size(double.infinity, MqSpacing.minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          ),
          side: const BorderSide(color: MqColors.red),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: MqColors.sand300,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // -- Dark theme --
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: MqColors.brightRed,
      brightness: Brightness.dark,
      primary: MqColors.brightRed,
      onPrimary: Colors.white,
      secondary: MqColors.magenta,
      onSecondary: Colors.white,
      error: MqColors.error,
      surface: MqColors.charcoal800,
      onSurface: MqColors.contentPrimaryDark,
      surfaceContainerHighest: MqColors.charcoal700,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: MqTypography.darkTextTheme,
      scaffoldBackgroundColor: MqColors.charcoal800,
      appBarTheme: const AppBarTheme(
        backgroundColor: MqColors.charcoal800,
        foregroundColor: MqColors.contentPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: MqColors.charcoal900,
        indicatorColor: MqColors.brightRed.withAlpha(30),
        elevation: 3,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: MqColors.slate500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: MqColors.charcoal700,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: MqSpacing.space4,
          vertical: MqSpacing.space2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MqColors.charcoal700,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MqSpacing.space4,
          vertical: MqSpacing.space3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          borderSide: const BorderSide(color: MqColors.charcoal600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          borderSide: const BorderSide(color: MqColors.charcoal600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          borderSide: const BorderSide(color: MqColors.brightRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          borderSide: const BorderSide(color: MqColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          borderSide: const BorderSide(color: MqColors.error, width: 2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MqColors.brightRed,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: MqColors.brightRed,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, MqSpacing.minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MqColors.brightRed,
          minimumSize: const Size(double.infinity, MqSpacing.minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MqSpacing.radiusMd),
          ),
          side: const BorderSide(color: MqColors.brightRed),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: MqColors.charcoal600,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
