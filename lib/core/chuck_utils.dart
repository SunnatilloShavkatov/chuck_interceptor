import 'package:flutter/foundation.dart' show kDebugMode;

///Utils used across multiple classes in app.
class ChuckUtils {
  static void log(String logMessage) {
    if (kDebugMode) {
      print(logMessage);
    }
  }
}
