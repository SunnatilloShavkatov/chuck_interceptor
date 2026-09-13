import 'package:chuck_interceptor/src/theme/chuck_theme.dart';
import 'package:material_ui/material_ui.dart';

/// Shows Chuck snack bars without assuming that the host app provides a
/// [ScaffoldMessenger] above Chuck's screens.
///
/// Chuck's screens install their own [ScaffoldMessenger], but Chuck widgets can
/// also be embedded by hosts. When no messenger is reachable the message is
/// logged instead of throwing, so copy actions never crash the app.
final class ChuckSnackBarHelper {
  const new _();

  static void show(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      debugPrint('Chuck: $message');
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: context.chuckTheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        content: Text(message, style: TextStyle(color: context.chuckTheme.onInverseSurface)),
      ),
    );
  }
}
