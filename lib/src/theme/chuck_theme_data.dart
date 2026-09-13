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

  static ThemeData buildTheme(Brightness brightness, {ChuckThemeExtension? extension}) {
    final ChuckThemeExtension resolvedExtension = extension ?? ChuckThemeExtension.fallback(brightness);
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: resolvedExtension.background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: resolvedExtension.background,
        surfaceTintColor: resolvedExtension.background,
        shadowColor: resolvedExtension.surfaceBorder,
        foregroundColor: resolvedExtension.primaryText,
        iconTheme: IconThemeData(color: resolvedExtension.primaryText),
      ),
      cardColor: resolvedExtension.surface,
      dividerColor: resolvedExtension.surfaceBorder,
      extensions: [resolvedExtension],
    );
  }
}
