import 'package:flutter/widgets.dart';

/// Shared spacing and corner-radius constants for the 60-30-10 design system.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// Default horizontal padding for screens.
  static const double screenPadding = 16;

  static const EdgeInsets screen =
      EdgeInsets.symmetric(horizontal: screenPadding);

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
}
