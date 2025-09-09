// Fallback para compiladores
abstract class PlatformCaps {
  bool get isWeb;
  bool get isAndroid;
  Future<bool> get isPhysicalDevice;
  bool get supportsLocalLlm; // Android o Windows soportan modelos offline
}

final PlatformCaps caps = _StubCaps();

class _StubCaps implements PlatformCaps {
  @override bool get isWeb => false;
  @override bool get isAndroid => false;
  @override Future<bool> get isPhysicalDevice async => true;
  @override bool get supportsLocalLlm => false;
}
