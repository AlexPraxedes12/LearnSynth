import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'platform_cap_stub.dart';

class _IoCaps implements PlatformCaps {
  final _devInfo = DeviceInfoPlugin();

  @override bool get isWeb => false;
  @override bool get isAndroid => Platform.isAndroid;

  @override Future<bool> get isPhysicalDevice async {
    if (Platform.isAndroid) {
      final info = await _devInfo.androidInfo;
      return info.isPhysicalDevice; // false = emulador
    }
    return true;
  }

  @override bool get supportsLocalLlm {
    // Offline models supported on Android and Windows desktops
    return Platform.isAndroid || Platform.isWindows;
  }
}

final PlatformCaps caps = _IoCaps();
