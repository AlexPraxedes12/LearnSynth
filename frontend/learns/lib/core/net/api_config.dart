// frontend/learns/lib/core/net/api_config.dart
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, kReleaseMode;
import '../../config/env.dart';

class ApiConfig {
  /// Base del backend para cada plataforma.
  static String get apiBase {
    final envBase = Env.apiBase;
    if (envBase.isNotEmpty) return envBase;
    if (kReleaseMode) return 'https://learnsynth-api.fly.dev';

    if (kIsWeb) return 'http://localhost:8000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000'; // Android emulator → host
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:8000';
      case TargetPlatform.fuchsia:
        return 'http://localhost:8000';
    }
  }

  /// Timeout for backend requests.
  static const Duration backendTimeout = Duration(minutes: 10);
}

