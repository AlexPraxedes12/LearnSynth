import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

bool get isOfflineModelSupported {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isWindows;
}
