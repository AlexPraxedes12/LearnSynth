import 'dart:typed_data';

import 'export_service_io.dart'
    if (dart.library.html) 'export_service_web.dart';

Future<String?> exportPack(Uint8List data, String fileName) {
  return exportPackImpl(data, fileName);
}
