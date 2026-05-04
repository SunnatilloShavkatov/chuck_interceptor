import 'package:chuck_interceptor/src/utils/chuck_constants.dart';
import 'package:flutter/material.dart';

@immutable
final class ChuckThemeExtension extends ThemeExtension<ChuckThemeExtension> {
  const ChuckThemeExtension({
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.error,
    required this.neutral,
    required this.primaryText,
    required this.secondaryText,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.errorPreviewBackground,
    required this.errorPreviewBorder,
  });

  factory ChuckThemeExtension.fallback(Brightness brightness) => brightness == Brightness.dark ? dark : light;

  final Color accent;
  final Color onAccent;
  final Color success;
  final Color warning;
  final Color error;
  final Color neutral;
  final Color primaryText;
  final Color secondaryText;
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color errorPreviewBackground;
  final Color errorPreviewBorder;

  static const ChuckThemeExtension light = ChuckThemeExtension(
    accent: ChuckConstants.lightRed,
    onAccent: Colors.white,
    success: ChuckConstants.green,
    warning: ChuckConstants.orange,
    error: ChuckConstants.red,
    neutral: ChuckConstants.grey,
    primaryText: Color(0xFF1F1F1F),
    secondaryText: Color(0xFF6B7280),
    inverseSurface: Color(0xFF2B2B2B),
    onInverseSurface: Colors.white,
    errorPreviewBackground: Color(0xFFFFEBEE),
    errorPreviewBorder: Color(0xFFEF9A9A),
  );

  static const ChuckThemeExtension dark = ChuckThemeExtension(
    accent: ChuckConstants.lightRed,
    onAccent: Colors.white,
    success: ChuckConstants.green,
    warning: ChuckConstants.orange,
    error: ChuckConstants.red,
    neutral: Color(0xFF8A94A6),
    primaryText: Color(0xFFF5F5F5),
    secondaryText: Color(0xFFB0B7C3),
    inverseSurface: Color(0xFFF5F5F5),
    onInverseSurface: Color(0xFF1B1B1B),
    errorPreviewBackground: Color(0xFF3A1F22),
    errorPreviewBorder: Color(0xFF9F4B52),
  );

  @override
  ChuckThemeExtension copyWith({
    Color? accent,
    Color? onAccent,
    Color? success,
    Color? warning,
    Color? error,
    Color? neutral,
    Color? primaryText,
    Color? secondaryText,
    Color? inverseSurface,
    Color? onInverseSurface,
    Color? errorPreviewBackground,
    Color? errorPreviewBorder,
  }) => ChuckThemeExtension(
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
    neutral: neutral ?? this.neutral,
    primaryText: primaryText ?? this.primaryText,
    secondaryText: secondaryText ?? this.secondaryText,
    inverseSurface: inverseSurface ?? this.inverseSurface,
    onInverseSurface: onInverseSurface ?? this.onInverseSurface,
    errorPreviewBackground: errorPreviewBackground ?? this.errorPreviewBackground,
    errorPreviewBorder: errorPreviewBorder ?? this.errorPreviewBorder,
  );

  @override
  ChuckThemeExtension lerp(ThemeExtension<ChuckThemeExtension>? other, double t) {
    if (other is! ChuckThemeExtension) {
      return this;
    }

    return ChuckThemeExtension(
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      onAccent: Color.lerp(onAccent, other.onAccent, t) ?? onAccent,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      error: Color.lerp(error, other.error, t) ?? error,
      neutral: Color.lerp(neutral, other.neutral, t) ?? neutral,
      primaryText: Color.lerp(primaryText, other.primaryText, t) ?? primaryText,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t) ?? secondaryText,
      inverseSurface: Color.lerp(inverseSurface, other.inverseSurface, t) ?? inverseSurface,
      onInverseSurface: Color.lerp(onInverseSurface, other.onInverseSurface, t) ?? onInverseSurface,
      errorPreviewBackground:
          Color.lerp(errorPreviewBackground, other.errorPreviewBackground, t) ?? errorPreviewBackground,
      errorPreviewBorder: Color.lerp(errorPreviewBorder, other.errorPreviewBorder, t) ?? errorPreviewBorder,
    );
  }
}

extension ChuckThemeBuildContextExtension on BuildContext {
  ChuckThemeExtension get chuckTheme =>
      Theme.of(this).extension<ChuckThemeExtension>() ?? ChuckThemeExtension.fallback(Theme.of(this).brightness);
}
