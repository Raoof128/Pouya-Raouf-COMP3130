import 'package:flutter/material.dart';

/// Macquarie University brand colour palette.
///
/// Sourced from the web app's mq-tokens.css and tailwind config.
abstract final class MqColors {
  // ── Brand ──────────────────────────────────────────────
  static const Color red = Color(0xFFA6192E);
  static const Color brightRed = Color(0xFFD6001C);
  static const Color deepRed = Color(0xFF76232F);
  static const Color magenta = Color(0xFFC6007E);
  static const Color purple = Color(0xFF80225F);

  // ── Alabaster (primary background family) ──────────────
  static const Color alabaster = Color(0xFFEDEADE);
  static const Color alabasterDark = Color(0xFFE5E2D4);
  static const Color alabasterLight = Color(0xFFF5F4ED);

  // ── Charcoal ───────────────────────────────────────────
  static const Color charcoal900 = Color(0xFF262826);
  static const Color charcoal800 = Color(0xFF373A36);
  static const Color charcoal700 = Color(0xFF535650);
  static const Color charcoal600 = Color(0xFF71736B);

  // ── Sand ───────────────────────────────────────────────
  static const Color sand100 = Color(0xFFF7F6F3);
  static const Color sand200 = Color(0xFFEAE8E1);
  static const Color sand300 = Color(0xFFD6D2C4);
  static const Color sand400 = Color(0xFFB3B1A5);
  static const Color sand500 = Color(0xFF919288);

  // ── Slate ──────────────────────────────────────────────
  static const Color slate100 = Color(0xFFECF2F6);
  static const Color slate200 = Color(0xFFD9E5ED);
  static const Color slate300 = Color(0xFFC6D8E4);
  static const Color slate400 = Color(0xFFB3CBDB);
  static const Color slate500 = Color(0xFF8D98A1);

  // ── Semantic ───────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Content (light mode) ───────────────────────────────
  static const Color contentPrimary = Color(0xFF1A1A1A);
  static const Color contentSecondary = Color(0xFF2B2B2B);
  static const Color contentTertiary = Color(0xFF4A4A44);

  // ── Dark mode content ──────────────────────────────────
  static const Color contentPrimaryDark = alabaster;
  static const Color contentSecondaryDark = Color(0xFFC4C6C0);

  // ── Map-specific ───────────────────────────────────────
  static const Color mapUserLocation = Color(0xFF29AAED);
  static const Color mapSelectedBuilding = Color(0xFFE8853A);
  static const Color mapRouteActive = Color(0xFF29AAED);
  static const Color mapParking = Color(0xFF9966CC);
  static const Color mapAccessibility = Color(0xFF4BD964);
  static const Color mapWater = Color(0xFF29AAED);
}
