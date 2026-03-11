import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:logger/logger.dart' as pkg;

/// Structured application logger.
///
/// Wraps the `logger` package with a consistent interface used across the app.
/// In release mode, only warnings and errors are logged.
class AppLogger {
  AppLogger._();

  static final pkg.Logger _logger = pkg.Logger(
    level: kReleaseMode ? pkg.Level.warning : pkg.Level.debug,
    printer: pkg.PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 5,
      lineLength: 100,
    ),
  );

  static void debug(String message, [Object? data]) {
    _logger.d('$message${data != null ? ' | $data' : ''}');
  }

  static void info(String message, [Object? data]) {
    _logger.i('$message${data != null ? ' | $data' : ''}');
  }

  static void warning(String message, [Object? error, StackTrace? stack]) {
    _logger.w(message, error: error, stackTrace: stack);
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    _logger.e(message, error: error, stackTrace: stack);
  }
}
