import 'package:flutter/foundation.dart';

///Utils used across multiple classes in app.
final class ChuckUtils {
  const new _();

  static void log(String logMessage) {
    if (kDebugMode) {
      print(logMessage);
    }
  }
}
