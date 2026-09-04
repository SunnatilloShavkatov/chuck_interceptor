import 'package:chuck_interceptor/src/utils/chuck_constants.dart';
import 'package:flutter/material.dart';

@immutable
final class ChuckThemeExtension extends ThemeExtension<ChuckThemeExtension> {
  const ChuckThemeExtension({
    required this.background,
    required this.surface,
    required this.surfaceBorder,
    required this.cardBackground,
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
    required this.statusLoading,
    required this.methodGet,
    required this.methodPost,
    required this.methodPut,
    required this.methodDelete,
    required this.methodPatch,
    required this.methodOther,
    required this.jsonKeyColor,
    required this.jsonStringColor,
    required this.jsonNumberColor,
    required this.jsonBooleanColor,
    required this.jsonNullColor,
  });

  factory ChuckThemeExtension.fallback(Brightness brightness) => brightness == Brightness.dark ? dark : light;

  final Color background;
  final Color surface;
  final Color surfaceBorder;
  final Color cardBackground;
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
  final Color statusLoading;
  final Color methodGet;
  final Color methodPost;
  final Color methodPut;
  final Color methodDelete;
  final Color methodPatch;
  final Color methodOther;
  final Color jsonKeyColor;
  final Color jsonStringColor;
  final Color jsonNumberColor;
  final Color jsonBooleanColor;
  final Color jsonNullColor;

  static const ChuckThemeExtension light = ChuckThemeExtension(
    surface: Color(0xFFF9FAFB),
    background: Color(0xFFF9FAFB),
    surfaceBorder: Color(0xFFE5E7EB),
    cardBackground: Color(0xFFF3F4F6),
    accent: ChuckConstants.lightRed,
    onAccent: Colors.white,
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    neutral: Color(0xFF9CA3AF),
    primaryText: Color(0xFF111827),
    secondaryText: Color(0xFF6B7280),
    inverseSurface: Color(0xFF1F2937),
    onInverseSurface: Colors.white,
    errorPreviewBackground: Color(0xFFFEF2F2),
    errorPreviewBorder: Color(0xFFFCA5A5),
    statusLoading: Color(0xFF3B82F6),
    methodGet: Color(0xFF059669),
    methodPost: Color(0xFF2563EB),
    methodPut: Color(0xFFD97706),
    methodDelete: Color(0xFFDC2626),
    methodPatch: Color(0xFF7C3AED),
    methodOther: Color(0xFF4B5563),
    jsonKeyColor: Color(0xFF1E293B),
    jsonStringColor: Color(0xFF16A34A),
    jsonNumberColor: Color(0xFF0284C7),
    jsonBooleanColor: Color(0xFFD97706),
    jsonNullColor: Color(0xFF94A3B8),
  );

  static const ChuckThemeExtension dark = ChuckThemeExtension(
    surface: Color(0xFF121212),
    background: Color(0xFF121212),
    surfaceBorder: Color(0xFF2E2E2E),
    cardBackground: Color(0xFF282828),
    accent: ChuckConstants.lightRed,
    onAccent: Colors.white,
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    neutral: Color(0xFF6B7280),
    primaryText: Color(0xFFF9FAFB),
    secondaryText: Color(0xFF9CA3AF),
    inverseSurface: Color(0xFFF3F4F6),
    onInverseSurface: Color(0xFF111827),
    errorPreviewBackground: Color(0xFF3A1B1F),
    errorPreviewBorder: Color(0xFF7F282F),
    statusLoading: Color(0xFF60A5FA),
    methodGet: Color(0xFF34D399),
    methodPost: Color(0xFF60A5FA),
    methodPut: Color(0xFFFBBF24),
    methodDelete: Color(0xFFF87171),
    methodPatch: Color(0xFFA78BFA),
    methodOther: Color(0xFF9CA3AF),
    jsonKeyColor: Color(0xFFE2E8F0),
    jsonStringColor: Color(0xFF4ADE80),
    jsonNumberColor: Color(0xFF38BDF8),
    jsonBooleanColor: Color(0xFFFB923C),
    jsonNullColor: Color(0xFF64748B),
  );

  Color getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return methodGet;
      case 'POST':
        return methodPost;
      case 'PUT':
        return methodPut;
      case 'DELETE':
        return methodDelete;
      case 'PATCH':
        return methodPatch;
      default:
        return methodOther;
    }
  }

  Color getStatusColor(int? status) {
    if (status == null || status == -1) {
      return error;
    }
    if (status >= 200 && status < 300) {
      return success;
    }
    if (status >= 300 && status < 400) {
      return warning;
    }
    if (status >= 400) {
      return error;
    }
    return neutral;
  }

  @override
  ChuckThemeExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceBorder,
    Color? cardBackground,
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
    Color? statusLoading,
    Color? methodGet,
    Color? methodPost,
    Color? methodPut,
    Color? methodDelete,
    Color? methodPatch,
    Color? methodOther,
    Color? jsonKeyColor,
    Color? jsonStringColor,
    Color? jsonNumberColor,
    Color? jsonBooleanColor,
    Color? jsonNullColor,
  }) => ChuckThemeExtension(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceBorder: surfaceBorder ?? this.surfaceBorder,
    cardBackground: cardBackground ?? this.cardBackground,
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
    statusLoading: statusLoading ?? this.statusLoading,
    methodGet: methodGet ?? this.methodGet,
    methodPost: methodPost ?? this.methodPost,
    methodPut: methodPut ?? this.methodPut,
    methodDelete: methodDelete ?? this.methodDelete,
    methodPatch: methodPatch ?? this.methodPatch,
    methodOther: methodOther ?? this.methodOther,
    jsonKeyColor: jsonKeyColor ?? this.jsonKeyColor,
    jsonStringColor: jsonStringColor ?? this.jsonStringColor,
    jsonNumberColor: jsonNumberColor ?? this.jsonNumberColor,
    jsonBooleanColor: jsonBooleanColor ?? this.jsonBooleanColor,
    jsonNullColor: jsonNullColor ?? this.jsonNullColor,
  );

  @override
  ChuckThemeExtension lerp(ThemeExtension<ChuckThemeExtension>? other, double t) {
    if (other is! ChuckThemeExtension) {
      return this;
    }

    return ChuckThemeExtension(
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t) ?? surfaceBorder,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t) ?? cardBackground,
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
      statusLoading: Color.lerp(statusLoading, other.statusLoading, t) ?? statusLoading,
      methodGet: Color.lerp(methodGet, other.methodGet, t) ?? methodGet,
      methodPost: Color.lerp(methodPost, other.methodPost, t) ?? methodPost,
      methodPut: Color.lerp(methodPut, other.methodPut, t) ?? methodPut,
      methodDelete: Color.lerp(methodDelete, other.methodDelete, t) ?? methodDelete,
      methodPatch: Color.lerp(methodPatch, other.methodPatch, t) ?? methodPatch,
      methodOther: Color.lerp(methodOther, other.methodOther, t) ?? methodOther,
      jsonKeyColor: Color.lerp(jsonKeyColor, other.jsonKeyColor, t) ?? jsonKeyColor,
      jsonStringColor: Color.lerp(jsonStringColor, other.jsonStringColor, t) ?? jsonStringColor,
      jsonNumberColor: Color.lerp(jsonNumberColor, other.jsonNumberColor, t) ?? jsonNumberColor,
      jsonBooleanColor: Color.lerp(jsonBooleanColor, other.jsonBooleanColor, t) ?? jsonBooleanColor,
      jsonNullColor: Color.lerp(jsonNullColor, other.jsonNullColor, t) ?? jsonNullColor,
    );
  }
}

extension ChuckThemeBuildContextExtension on BuildContext {
  ChuckThemeExtension get chuckTheme =>
      Theme.of(this).extension<ChuckThemeExtension>() ?? ChuckThemeExtension.fallback(Theme.of(this).brightness);
}
