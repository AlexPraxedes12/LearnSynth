import 'package:flutter/foundation.dart' show kIsWeb;
import 'platform_cap_stub.dart';

class _WebCaps implements PlatformCaps {
  @override bool get isWeb => true;
  @override bool get isAndroid => false;
  @override Future<bool> get isPhysicalDevice async => false;
  @override bool get supportsLocalLlm => false; // No local LLM en Web
}

final PlatformCaps caps = _WebCaps();
