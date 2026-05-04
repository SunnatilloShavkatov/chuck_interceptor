import 'package:chuck_interceptor/src/theme/chuck_theme.dart';
import 'package:flutter/material.dart';

final class ChuckThemeData {
  const ChuckThemeData._();

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
}
