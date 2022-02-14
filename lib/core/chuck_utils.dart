import 'package:flutter/foundation.dart';

///Utils used across multiple classes in app.
class ChuckUtils {
  static void log(String logMessage) {
    if (!kReleaseMode) {
      // ignore: avoid_print
      print(logMessage);
    }
  }
}
