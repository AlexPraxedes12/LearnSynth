import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String?> exportPackImpl(Uint8List data, String fileName) async {
  try {
    Directory? directory;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      if (sdkInt <= 29) {
        final status = await Permission.storage.request();
        if (!status.isGranted) return null;
      } else {
        final status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) return null;
      }
      final dirs = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      directory = dirs?.isNotEmpty == true ? dirs!.first : null;
    } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      directory = await getDownloadsDirectory();
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    }

    directory ??= await getApplicationDocumentsDirectory();

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(data);
    return file.path;
  } catch (_) {
    return null;
  }
}
