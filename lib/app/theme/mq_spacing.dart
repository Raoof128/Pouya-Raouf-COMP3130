/// Macquarie University spacing & radius tokens.
///
/// Mapped from --c-space-* and --c-radius-* CSS custom properties.
abstract final class MqSpacing {
  // ── Spacing scale ──────────────────────────────────────
  static const double space1 = 4; // 0.25rem
  static const double space2 = 8; // 0.5rem
  static const double space3 = 12; // 0.75rem
  static const double space4 = 16; // 1rem
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;

  // ── Border radius ──────────────────────────────────────
  static const double radiusSm = 2; // 0.125rem
  static const double radius = 4; // 0.25rem
  static const double radiusMd = 8; // 0.5rem
  static const double radiusLg = 12; // 0.75rem
  static const double radiusXl = 16;
  static const double radiusFull = 999;

  // ── Minimum tap target (accessibility) ─────────────────
  static const double minTapTarget = 48;

  // ── Icon sizes ───────────────────────────────────────────
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconDefault = 24;
  static const double iconLg = 32;
  static const double iconXl = 40;
  static const double iconHero = 56;
}
