import 'package:flutter/material.dart';

import 'palette.dart';

/// Design language: soft ledger.
/// - Neutral chrome, text-driven actions, 10px radius everywhere.
/// - Flat: 1px borders, zero elevation. Softness comes from radius +
///   layered surfaces, not shadows.
/// - Income/expense are the only hues outside neutrals + focus accent.
ThemeData themeFor(AppPalette p) {
  OutlineInputBorder outline([Color? color, double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius),
        borderSide: BorderSide(color: color ?? p.border, width: width),
      );

  final colorScheme = ColorScheme(
    brightness: p.brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    secondary: p.accent,
    onSecondary: Colors.white,
    error: p.expense,
    onError: Colors.white,
    surface: p.surface,
    onSurface: p.text,
    surfaceContainerHighest: p.surfaceHigh,
    onSurfaceVariant: p.textMuted,
    outline: p.border,
    outlineVariant: p.track,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: p.bg,
    extensions: [p],

    // ── Typography — one scale, tight tracking on headings ──────────────
    textTheme: Typography.material2021().black
        .apply(bodyColor: p.text, displayColor: p.text)
        .copyWith(
          headlineMedium: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.2,
          ),
          titleLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.3,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            height: 1.4,
          ),
          titleSmall: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            height: 1.4,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          bodySmall: TextStyle(fontSize: 12, color: p.textMuted, height: 1.4),
          labelLarge: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),

    iconTheme: IconThemeData(color: p.text, size: 24),

    // ── AppBar — flat, with a 1px rule underneath ────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: p.surface,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      shape: Border(bottom: BorderSide(color: p.border, width: 1)),
      titleTextStyle: TextStyle(
        color: p.text,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: p.text),
    ),

    // ── Navigation bar — soft indicator instead of the M3 pill ──────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      indicatorColor: p.primary.withValues(alpha: 0.08),
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(kRadius)),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: p.text,
          );
        }
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: p.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: p.text);
        }
        return IconThemeData(color: p.textMuted);
      }),
    ),

    // ── Cards — layered surface, bordered, flat ─────────────────────────
    cardTheme: CardThemeData(
      color: p.surfaceHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(kRadius)),
        side: BorderSide(color: p.border, width: 1),
      ),
    ),

    // ── Inputs ───────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: outline(),
      enabledBorder: outline(),
      focusedBorder: outline(p.accent, 1.2),
      errorBorder: outline(p.expense),
      focusedErrorBorder: outline(p.expense, 1.2),
      labelStyle: TextStyle(
        color: p.textMuted,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(color: p.textMuted, fontSize: 14),
      errorStyle: TextStyle(color: p.expense, fontSize: 12),
    ),

    dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),

    // ── Chips — selected = primary fill ─────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: p.surfaceHigh,
      surfaceTintColor: Colors.transparent,
      selectedColor: p.primary,
      checkmarkColor: p.onPrimary,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: p.text,
      ),
      secondaryLabelStyle: TextStyle(
        color: p.onPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(color: p.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // ── Segmented buttons — selected segment is a primary block ─────────
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: p.border)),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(kRadius)),
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.primary : p.surfaceHigh,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.onPrimary : p.textMuted,
        ),
        visualDensity: VisualDensity.comfortable,
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
    ),

    // ── Buttons ──────────────────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        disabledBackgroundColor: p.track,
        disabledForegroundColor: p.textMuted,
        elevation: 0,
        visualDensity: VisualDensity.standard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(kRadius)),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.text,
        side: BorderSide(color: p.border),
        elevation: 0,
        visualDensity: VisualDensity.standard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(kRadius)),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.text,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(kRadius)),
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: p.text,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(kRadius)),
        ),
      ),
    ),

    // ── List tiles ───────────────────────────────────────────────────────
    listTileTheme: ListTileThemeData(
      iconColor: p.textMuted,
      titleTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        color: p.text,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 13,
        color: p.textMuted,
        height: 1.35,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(kRadius)),
      ),
    ),

    // ── Overlays — flat panels with a 1px border, no shadow ─────────────
    dialogTheme: DialogThemeData(
      backgroundColor: p.surfaceHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(kRadius)),
        side: BorderSide(color: p.border, width: 1),
      ),
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: p.text,
      ),
      contentTextStyle: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: p.textMuted,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surfaceHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(kRadius)),
        side: BorderSide(color: p.border, width: 1),
      ),
      textStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: p.text,
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.surfaceHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(kRadius)),
        side: BorderSide(color: p.border, width: 1),
      ),
      dayShape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(kRadius)),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.primary,
      elevation: 0,
      contentTextStyle: TextStyle(
        color: p.onPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      actionTextColor: p.onPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(kRadius)),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.primary,
      foregroundColor: p.onPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: p.primary,
        borderRadius: BorderRadius.circular(kRadius),
      ),
      textStyle: TextStyle(
        color: p.onPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
    tabBarTheme: TabBarThemeData(
      labelColor: p.text,
      unselectedLabelColor: p.textMuted,
      indicatorColor: p.primary,
      dividerColor: p.border,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surfaceHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(kRadius),
        ),
        side: BorderSide(color: p.border, width: 1),
      ),
    ),
  );
}

final ThemeData lightTheme = themeFor(AppPalette.monoLight);
final ThemeData darkTheme = themeFor(AppPalette.monoDark);
