import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────
/// Design language: "boxy ledger".
/// - Stone/slate neutrals, ink = slate-900.
/// - 1px slate-200 borders, zero elevation, 2px corner radius everywhere.
/// - Sharp (non-rounded) icon variants.
/// - Income/expense are desaturated semantic accents, used sparingly —
///   never as chrome.
/// ─────────────────────────────────────────────────────────────────────

// ── Tokens (import these in screens; do not hardcode colors) ──────────

/// Corner radius for every shaped surface.
const double kRadius = 2;

/// 1px outline color.
const Color kBorder = Color(0xFFE2E8F0); // slate-200

/// Ink scale.
const Color kInk = Color(0xFF0F172A); // slate-900 — primary text & actions
const Color kInkSecondary = Color(0xFF475569); // slate-600 — secondary text
const Color kInkMuted = Color(0xFF94A3B8); // slate-400 — hints / disabled

/// Semantic accents (AA contrast on white; accents only).
const Color kIncome = Color(0xFF047857); // emerald-700
const Color kIncomeSoft = Color(0xFFECFDF5); // emerald-50
const Color kExpense = Color(0xFFBE123C); // rose-700
const Color kExpenseSoft = Color(0xFFFFF1F2); // rose-50

const Color _surface = Color(0xFFF8FAFC); // slate-50
const Color _seed = Color(0xFF1E293B); // slate-800
/// Sunken surface for flush footers/toolbars (slate-100).
const Color kSurfaceMuted = Color(0xFFF1F5F9);

OutlineInputBorder _outline([Color color = kBorder, double width = 1]) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(kRadius),
      borderSide: BorderSide(color: color, width: width),
    );

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.light,
    primary: kInk, // every M3 control reading `primary` becomes ink
    onPrimary: Colors.white,
    surface: _surface,
  ),
  scaffoldBackgroundColor: _surface,

  // ── Typography — one scale, tight tracking on headings ──────────────
  textTheme: Typography.material2021().black
      .apply(bodyColor: kInk, displayColor: kInk)
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
        bodySmall: const TextStyle(
          fontSize: 12,
          color: kInkSecondary,
          height: 1.4,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),

  iconTheme: const IconThemeData(color: kInk, size: 24),

  // ── AppBar — flat, with a 1px rule underneath ────────────────────────
  appBarTheme: const AppBarTheme(
    backgroundColor: _surface,
    scrolledUnderElevation: 0,
    elevation: 0,
    centerTitle: false,
    shape: Border(bottom: BorderSide(color: kBorder, width: 1)),
    titleTextStyle: TextStyle(
      color: kInk,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    iconTheme: IconThemeData(color: kInk),
  ),

  // ── Navigation bar — boxed indicator instead of the M3 pill ─────────
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    height: 64,
    indicatorColor: kInk.withValues(alpha: 0.08),
    indicatorShape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(kRadius)),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: kInk,
        );
      }
      return const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: kInkSecondary,
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: kInk);
      }
      return const IconThemeData(color: kInkSecondary);
    }),
  ),

  // ── Cards — white, bordered, flat. Margin is explicit per screen. ───
  cardTheme: CardThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(kRadius)),
      side: BorderSide(color: kBorder, width: 1),
    ),
  ),

  // ── Inputs ───────────────────────────────────────────────────────────
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: _outline(),
    enabledBorder: _outline(),
    focusedBorder: _outline(kInk, 1.2),
    errorBorder: _outline(kExpense),
    focusedErrorBorder: _outline(kExpense, 1.2),
    labelStyle: const TextStyle(
      color: kInkSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    hintStyle: const TextStyle(color: kInkMuted, fontSize: 14),
    errorStyle: const TextStyle(color: kExpense, fontSize: 12),
  ),

  dividerTheme: const DividerThemeData(color: kBorder, thickness: 1, space: 1),

  // ── Chips — boxy; selected = ink fill with white text/checkmark ─────
  chipTheme: ChipThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    selectedColor: kInk,
    checkmarkColor: Colors.white,
    labelStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: kInk,
    ),
    secondaryLabelStyle: const TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    side: const BorderSide(color: kBorder),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),

  // ── Segmented buttons — selected segment is an ink block ────────────
  segmentedButtonTheme: SegmentedButtonThemeData(
    style: ButtonStyle(
      side: const WidgetStatePropertyAll(BorderSide(color: kBorder)),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(kRadius)),
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? kInk : Colors.white,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : kInkSecondary,
      ),
      visualDensity: .comfortable,
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
      backgroundColor: kInk,
      foregroundColor: Colors.white,
      disabledBackgroundColor: kInk.withValues(alpha: 0.10),
      disabledForegroundColor: kInkMuted,
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
      foregroundColor: kInk,
      side: const BorderSide(color: kBorder),
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
      foregroundColor: kInk,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(kRadius)),
      ),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: kInk,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(kRadius)),
      ),
    ),
  ),

  // ── List tiles ───────────────────────────────────────────────────────
  listTileTheme: ListTileThemeData(
    iconColor: kInkSecondary,
    titleTextStyle: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.1,
      color: kInk,
    ),
    subtitleTextStyle: const TextStyle(
      fontSize: 13,
      color: kInkSecondary,
      height: 1.35,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(kRadius)),
    ),
  ),

  // ── Overlays — flat white panels with a 1px border, no shadow ───────
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(kRadius)),
      side: BorderSide(color: kBorder, width: 1),
    ),
    titleTextStyle: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: kInk,
    ),
    contentTextStyle: const TextStyle(
      fontSize: 14,
      height: 1.5,
      color: kInkSecondary,
    ),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(kRadius)),
      side: BorderSide(color: kBorder, width: 1),
    ),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: kInk,
    ),
  ),
  datePickerTheme: DatePickerThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(kRadius)),
      side: BorderSide(color: kBorder, width: 1),
    ),
    dayShape: const WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(kRadius)),
      ),
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: kInk,
    elevation: 0,
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    actionTextColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(kRadius)),
    ),
  ),

  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: kInk,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
  ),
  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: kInk,
      borderRadius: BorderRadius.circular(kRadius),
    ),
    textStyle: const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(color: kInk),
  // Add — so TabBar needs zero inline styling:
  tabBarTheme: const TabBarThemeData(
    labelColor: kInk,
    unselectedLabelColor: kInkMuted,
    indicatorColor: kInk,
    dividerColor: kBorder,
    labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  ),

  // Replace bottomSheetTheme with (adds the 1px rule, so showModalBottomSheet
  // can be called bare):
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(kRadius)),
      side: BorderSide(color: kBorder, width: 1),
    ),
  ),
);
