import 'package:chuck_interceptor/src/theme/chuck_theme.dart';
import 'package:material_ui/material_ui.dart';

final class ChuckThemeData {
  const new _();

  static ThemeData attach(ThemeData base, {ChuckThemeExtension? extension}) {
    final Brightness brightness = base.brightness;
    final ChuckThemeExtension resolvedExtension =
        extension ?? base.extension<ChuckThemeExtension>() ?? ChuckThemeExtension.fallback(brightness);
    final List<ThemeExtension<dynamic>> extensions =
        base.extensions.values
            .where((extension) => extension is! ChuckThemeExtension)
            .cast<ThemeExtension<dynamic>>()
            .toList()
          ..add(resolvedExtension);
    return base.copyWith(extensions: extensions);
  }

  /// Builds Chuck's own [ThemeData] for the given [brightness].
  ///
  /// The returned theme is standalone: it does NOT inherit colors, typography,
  /// tab or button styling from the host application, so the inspector always
  /// looks the same no matter how the surrounding app is themed.
  static ThemeData buildTheme(Brightness brightness, {ChuckThemeExtension? extension}) {
    final ChuckThemeExtension ext = extension ?? ChuckThemeExtension.fallback(brightness);
    final isDark = brightness == Brightness.dark;
    final ThemeData base = isDark ? ThemeData.dark() : ThemeData.light();
    final ColorScheme scheme = base.colorScheme.copyWith(
      primary: ext.accent,
      onPrimary: ext.onAccent,
      secondary: ext.accent,
      onSecondary: ext.onAccent,
      surface: ext.surface,
      onSurface: ext.primaryText,
      error: ext.error,
      outline: ext.surfaceBorder,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: ext.background,
      canvasColor: ext.background,
      cardColor: ext.surface,
      dividerColor: ext.surfaceBorder,
      iconTheme: IconThemeData(color: ext.primaryText),
      dividerTheme: DividerThemeData(color: ext.surfaceBorder, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: ext.background,
        surfaceTintColor: ext.background,
        shadowColor: ext.surfaceBorder,
        foregroundColor: ext.primaryText,
        iconTheme: IconThemeData(color: ext.primaryText),
        actionsIconTheme: IconThemeData(color: ext.primaryText),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: ext.accent,
        unselectedLabelColor: ext.secondaryText,
        indicatorColor: ext.accent,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: ext.surfaceBorder,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ext.accent,
        foregroundColor: ext.onAccent,
        elevation: 3,
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: ext.accent)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: ext.accent, foregroundColor: ext.onAccent),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? ext.accent : ext.neutral,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ext.surface,
        surfaceTintColor: ext.surface,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ext.primaryText),
        contentTextStyle: TextStyle(fontSize: 14, color: ext.secondaryText),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ext.inverseSurface,
        contentTextStyle: TextStyle(color: ext.onInverseSurface),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: [ext],
    );
  }

  /// Chuck's own theme, resolved for the current [context].
  ///
  /// Only the brightness and an optional [ChuckThemeExtension] override are
  /// taken from the host application - everything else comes from Chuck, so
  /// the inspector keeps its default design inside any app.
  static ThemeData isolate(BuildContext context, {ChuckThemeExtension? extension, Brightness? brightness}) {
    final ThemeData app = Theme.of(context);
    return buildTheme(brightness ?? app.brightness, extension: extension ?? app.extension<ChuckThemeExtension>());
  }
}
