import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('devoverflow');

void initLogger() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
  Logger.root.onRecord.listen((rec) {
    // Print in debug mode only; production can integrate with crash/reporting
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        '${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}',
      );
    }
  });
}

void logInfo(String msg) => _logger.info(msg);
void logWarn(String msg) => _logger.warning(msg);
void logError(String msg) => _logger.severe(msg);
