import 'package:flutter/material.dart';

/// PrivateAgent centralized color system — the 60-30-10 palette.
///
/// * 60% PRIMARY   `#FFFFFF` white / very light backgrounds
/// * 30% SECONDARY `#000000` black + near-black surfaces & typography
/// * 10% ACCENT    `#E21B23` red — CTAs, active/selected states,
///   progress and important indicators only
///
/// All screens and widgets consume these semantic colors instead of raw
/// `Colors.*` or `Color(0x…)` literals.
class AppColors {
  AppColors._();

  // ----------------------------------------------------------------- 60% ---
  /// Main app background (light theme).
  static const Color background = Color(0xFFFFFFFF);

  /// Subtle light surface — agent chat bubbles, quiet fills.
  static const Color surfaceMuted = Color(0xFFF4F4F4);

  /// Light surface variant — tonal controls, selected-segment fallback.
  static const Color surfaceMutedHigh = Color(0xFFEDEDED);

  // ----------------------------------------------------------------- 30% ---
  /// Pure black — typography, app bar / navigation surfaces.
  static const Color secondary = Color(0xFF000000);

  /// Near-black surface — active task bar, dark theme scaffold.
  static const Color surfaceDark = Color(0xFF111111);

  /// Near-black surface variant — cards/inputs in dark theme, dark chips.
  static const Color surfaceDarkVariant = Color(0xFF1A1A1A);

  /// Primary text (light theme).
  static const Color textPrimary = Color(0xFF000000);

  /// Text and icons on dark surfaces.
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ----------------------------------------------------------------- 10% ---
  /// Accent red — primary CTA, active/selected states, progress.
  static const Color accent = Color(0xFFE21B23);

  /// Pressed accent.
  static const Color accentPressed = Color(0xFFB51218);

  /// Accent tint for active-state backgrounds (banners, selection).
  static const Color accentLight = Color(0xFFFDE7E8);

  // ------------------------------------------------------------- utilities ---
  /// Hairline border (light theme).
  static const Color border = Color(0xFFD9D9D9);

  /// Hairline border (dark theme).
  static const Color borderDark = Color(0xFF2E2E2E);

  /// Secondary/muted text on light surfaces.
  static const Color textMuted = Color(0xFF6B6B6B);

  /// Secondary/muted text on dark surfaces.
  static const Color textMutedDark = Color(0xFF9B9B9B);

  /// Success status.
  static const Color success = Color(0xFF1B8A3A);

  /// Warning status.
  static const Color warning = Color(0xFFD98C00);

  /// Error/failure status.
  static const Color error = Color(0xFFD71920);
}
