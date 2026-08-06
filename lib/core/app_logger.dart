import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void error(String context, Object error, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;

    debugPrint('[$context] $error');

    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
