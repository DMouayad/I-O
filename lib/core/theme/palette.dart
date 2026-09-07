import 'package:flutter/material.dart';

/// Corner radius for every shaped surface.
const double kRadius = 10;

/// Semantic palette. Light + dark are first-class; screens read it via
/// `context.pal` so both appearances work with zero branching.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.track,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.primary,
    required this.onPrimary,
    required this.income,
    required this.incomeSoft,
    required this.expense,
    required this.expenseSoft,
  });

  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color track;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color primary;
  final Color onPrimary;

  /// Money colors — the only hues outside neutrals + accent.
  final Color income;
  final Color incomeSoft;
  final Color expense;
  final Color expenseSoft;

  static const monoLight = AppPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF2F2F5),
    surface: Color(0xFFF2F2F5),
    surfaceHigh: Color(0xFFFFFFFF),
    track: Color(0xFFE5E5EA),
    border: Color(0xFFDBDBE1),
    text: Color(0xFF0A0A0B),
    textMuted: Color(0xFF6B6B70),
    accent: Color(0xFF2563EB),
    primary: Color(0xFF0A0A0B),
    onPrimary: Color(0xFFFFFFFF),
    income: Color(0xFF047857),
    incomeSoft: Color(0xFFECFDF5),
    expense: Color(0xFFBE123C),
    expenseSoft: Color(0xFFFFF1F2),
  );

  static const monoDark = AppPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF000000),
    surface: Color(0xFF0E0E10),
    surfaceHigh: Color(0xFF17171A),
    track: Color(0xFF232328),
    border: Color(0xFF2F2F35),
    text: Color(0xFFF5F5F6),
    textMuted: Color(0xFF9A9AA0),
    accent: Color(0xFF3B82F6),
    primary: Color(0xFFF5F5F6),
    onPrimary: Color(0xFF0A0A0B),
    income: Color(0xFF34D399),
    incomeSoft: Color(0xFF0C2B23),
    expense: Color(0xFFFB7185),
    expenseSoft: Color(0xFF3A1420),
  );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? bg,
    Color? surface,
    Color? surfaceHigh,
    Color? track,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? accent,
    Color? primary,
    Color? onPrimary,
    Color? income,
    Color? incomeSoft,
    Color? expense,
    Color? expenseSoft,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      track: track ?? this.track,
      border: border ?? this.border,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      income: income ?? this.income,
      incomeSoft: incomeSoft ?? this.incomeSoft,
      expense: expense ?? this.expense,
      expenseSoft: expenseSoft ?? this.expenseSoft,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: lerpColor(bg, other.bg),
      surface: lerpColor(surface, other.surface),
      surfaceHigh: lerpColor(surfaceHigh, other.surfaceHigh),
      track: lerpColor(track, other.track),
      border: lerpColor(border, other.border),
      text: lerpColor(text, other.text),
      textMuted: lerpColor(textMuted, other.textMuted),
      accent: lerpColor(accent, other.accent),
      primary: lerpColor(primary, other.primary),
      onPrimary: lerpColor(onPrimary, other.onPrimary),
      income: lerpColor(income, other.income),
      incomeSoft: lerpColor(incomeSoft, other.incomeSoft),
      expense: lerpColor(expense, other.expense),
      expenseSoft: lerpColor(expenseSoft, other.expenseSoft),
    );
  }
}

extension PaletteOf on BuildContext {
  AppPalette get pal => Theme.of(this).extension<AppPalette>()!;
}
