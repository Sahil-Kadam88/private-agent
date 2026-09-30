import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// PrivateAgent design system — the 60-30-10 "white / black / red" theme.
///
/// * 60% white / very light backgrounds
/// * 30% black surfaces and typography (app bar, task bar, chat bubbles)
/// * 10% red accent, reserved for CTAs, active/selected states,
///   progress indicators and error states
///
/// Both light and dark variants keep this hierarchy: the light theme is the
/// primary experience; the dark theme maps "background" to `#111111` and
/// keeps red as the accent.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  // --------------------------------------------------------------------------

  static ColorScheme _colorScheme({required bool isDark}) {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    if (!isDark) {
      return base.copyWith(
        // Accent drives CTAs, active states, progress.
        primary: AppColors.accent,
        onPrimary: AppColors.textOnDark,
        primaryContainer: AppColors.accentLight,
        onPrimaryContainer: AppColors.accentPressed,
        // Secondary = black (user chat bubbles, tonal contrast).
        secondary: AppColors.secondary,
        onSecondary: AppColors.textOnDark,
        secondaryContainer: AppColors.surfaceMutedHigh,
        onSecondaryContainer: AppColors.textPrimary,
        tertiary: AppColors.secondary,
        onTertiary: AppColors.textOnDark,
        error: AppColors.error,
        onError: AppColors.textOnDark,
        errorContainer: AppColors.accentLight,
        onErrorContainer: AppColors.accentPressed,
        // 60%: white / very light surfaces.
        surface: AppColors.background,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textMuted,
        outline: AppColors.border,
        outlineVariant: const Color(0xFFEAEAEA),
        surfaceDim: const Color(0xFFE8E8E8),
        surfaceContainerLowest: AppColors.background,
        surfaceContainerLow: const Color(0xFFFAFAFA),
        surfaceContainer: const Color(0xFFF7F7F7),
        surfaceContainerHigh: AppColors.surfaceMuted,
        surfaceContainerHighest: AppColors.surfaceMutedHigh,
        inverseSurface: AppColors.surfaceDark,
        onInverseSurface: AppColors.textOnDark,
        shadow: AppColors.secondary,
      );
    }

    return base.copyWith(
      primary: AppColors.accent,
      onPrimary: AppColors.textOnDark,
      primaryContainer: AppColors.accentPressed,
      onPrimaryContainer: AppColors.accentLight,
      secondary: AppColors.textOnDark,
      onSecondary: AppColors.secondary,
      secondaryContainer: AppColors.surfaceDarkVariant,
      onSecondaryContainer: AppColors.textOnDark,
      tertiary: AppColors.textOnDark,
      onTertiary: AppColors.secondary,
      error: AppColors.error,
      onError: AppColors.textOnDark,
      errorContainer: AppColors.accentPressed,
      onErrorContainer: AppColors.accentLight,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textOnDark,
      onSurfaceVariant: AppColors.textMutedDark,
      outline: AppColors.borderDark,
      outlineVariant: const Color(0xFF242424),
      surfaceDim: const Color(0xFF0A0A0A),
      surfaceContainerLowest: const Color(0xFF0C0C0C),
      surfaceContainerLow: const Color(0xFF161616),
      surfaceContainer: AppColors.surfaceDarkVariant,
      surfaceContainerHigh: const Color(0xFF222222),
      surfaceContainerHighest: const Color(0xFF2A2A2A),
      inverseSurface: const Color(0xFFEDEDED),
      onInverseSurface: AppColors.textPrimary,
      shadow: Colors.black,
    );
  }

  // --------------------------------------------------------------------------

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = _colorScheme(isDark: isDark);
    final border = isDark ? AppColors.borderDark : AppColors.border;
    final onDark = AppColors.textOnDark;
    final onLight = AppColors.secondary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.background,

      // Black navigation surface (30%) with white content.
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.secondary,
        foregroundColor: onDark,
        iconTheme: IconThemeData(color: onDark),
        actionsIconTheme: IconThemeData(color: onDark),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: onDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? AppColors.surfaceDarkVariant : AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: border),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? AppColors.surfaceDarkVariant : AppColors.background,
        hintStyle: TextStyle(
          color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Primary CTA = accent red.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: onDark,
          disabledBackgroundColor:
              isDark ? const Color(0xFF4A1D1F) : const Color(0xFFF3BDBF),
          disabledForegroundColor: onDark.withValues(alpha: 0.75),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),

      // Passive text actions stay black/white — accent is not spent here.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? onDark : onLight,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? onDark : onLight,
          side: BorderSide(
            color: isDark ? AppColors.textMutedDark : AppColors.secondary,
            width: 1.2,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),

      // Selected segment = accent; unselected = quiet surface.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.accent
                : null,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? onDark
                : (isDark ? onDark : onLight),
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.selected)
                  ? AppColors.accent
                  : border,
            ),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),

      // Choice chips (provider selection): selected = accent.
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        side: BorderSide(color: border),
        backgroundColor:
            isDark ? AppColors.surfaceDarkVariant : AppColors.background,
        labelStyle: TextStyle(
          color: isDark ? onDark : onLight,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: AppColors.accent,
        secondaryLabelStyle: const TextStyle(
          color: AppColors.textOnDark,
          fontWeight: FontWeight.w700,
        ),
        checkmarkColor: AppColors.textOnDark,
      ),

      // Switch = active state = accent.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.textOnDark
              : (isDark ? AppColors.textMutedDark : AppColors.background),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      // Slider = active state = accent.
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        thumbColor: AppColors.accent,
        inactiveTrackColor: border,
        overlayColor: AppColors.accent.withValues(alpha: 0.12),
      ),

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.accent),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: AppColors.accentLight,
        selectionHandleColor: AppColors.accent,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.background : AppColors.surfaceDark,
        contentTextStyle: TextStyle(
          color: isDark ? AppColors.textPrimary : AppColors.textOnDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceDarkVariant : AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),

      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
      ),
    );
  }
}
