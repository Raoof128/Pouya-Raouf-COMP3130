import 'package:flutter/material.dart';
import 'package:mq_navigation/app/theme/mq_colors.dart';

/// Macquarie University typography scale.
///
/// Primary: system sans-serif.  Secondary: system serif.
/// To enable branded fonts, add Work Sans and Source Serif Pro to
/// pubspec.yaml under the `fonts:` section.
/// Sizes mapped from the web app's token system.
abstract final class MqTypography {
  // Set to 'WorkSans'/'SourceSerifPro' once fonts are bundled in pubspec.yaml.
  static const String? _fontPrimary = null;
  static const String? _fontSecondary = null;

  // ── Light theme text styles ────────────────────────────
  static TextTheme get lightTextTheme =>
      _buildTextTheme(MqColors.contentPrimary);

  // ── Dark theme text styles ─────────────────────────────
  static TextTheme get darkTextTheme =>
      _buildTextTheme(MqColors.contentPrimaryDark);

  static TextTheme _buildTextTheme(Color baseColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _fontPrimary,
        fontSize: 48, // 3rem → 48px
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontFamily: _fontPrimary,
        fontSize: 36, // 2.25rem
        fontWeight: FontWeight.w700,
        color: baseColor,
        height: 1.15,
      ),
      displaySmall: TextStyle(
        fontFamily: _fontPrimary,
        fontSize: 30, // 1.875rem
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.2,
      ),
      headlineLarge: TextStyle(
        fontFamily: _fontPrimary,
        fontSize: 24, // 1.5rem
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.25,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontPrimary,
        fontSize: 20, // 1.25rem
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontFamily: _fontPrimary,
        fontSize: 18, // 1.125rem
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.35,
      ),
      titleLarge: TextStyle(
        fontFamily: _fontPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontPrimary,
        fontSize: 16, // 1rem
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      titleSmall: TextStyle(
        fontFamily: _fontPrimary,
        fontSize: 14, // 0.875rem
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: _fontPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontPrimary,
        fontSize: 12, // 0.75rem
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      labelLarge: TextStyle(
        fontFamily: _fontPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: _fontPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: baseColor,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontFamily: _fontPrimary,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: baseColor,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Serif text style for accent/editorial text.
  static TextStyle serif({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: _fontSecondary,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}
