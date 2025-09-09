// platform_cap.dart
export 'platform_cap_stub.dart'
  if (dart.library.io) 'platform_cap_io.dart'
  if (dart.library.html) 'platform_cap_web.dart';
