import 'dart:convert';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:crypto/crypto.dart';
import '../net/backend_client.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'models_fs.dart';

class ModelInfo {
  final String id;
  final String name;      // nombre de archivo real
  final int sizeBytes;
  final String sha256;
  final List<Uri> mirrors;
  const ModelInfo({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.sha256,
    required this.mirrors,
  });
}

class ModelCatalog {
  static final Uri manifestUri = Uri.parse(
    'https://huggingface.co/AlexMelodexa/LearnSynth-Models/resolve/main/manifest.json',
  );

  Future<List<ModelInfo>> fetch() async {
    final r = await BackendClient.get(manifestUri);
    if (r.statusCode != 200) {
      throw Exception('Manifest fetch error: ${r.statusCode}');
    }
    final data = json.decode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final List items = data['models'] as List;
    return items.map((m) {
      return ModelInfo(
        id: (m['id'] as String),
        name: (m['name'] as String),
        sizeBytes: (m['size_bytes'] as num).toInt(),
        sha256: (m['sha256'] as String),
        mirrors: (m['mirrors'] as List).map((e) => Uri.parse(e as String)).toList(),
      );
    }).toList();
  }
}

class ModelDownloader {
  final FileDownloader _bd = FileDownloader();

  /// Descarga a cache, valida tamaño+sha256 y mueve a /files/models
  Future<File?> downloadModel({
    required String filename,
    required List<Uri> mirrors,
    required String expectedSha256,
    required int expectedSize,
    void Function(double p)? onProgress,
  }) async {
    final cacheDir = await getTemporaryDirectory();
    final tmpPath = p.join(cacheDir.path, 'dl_$filename');

    for (final uri in mirrors) {
      final task = DownloadTask(
        url: uri.toString(),
        filename: p.basename(tmpPath),
        directory: cacheDir.path,
        updates: Updates.statusAndProgress,
        retries: 2,
        allowPause: true,
        metaData: 'model',
      );

      final res = await _bd.download(task, onProgress: (p) => onProgress?.call(p));
      if (res.status == TaskStatus.complete) {
        final f = File(tmpPath);
        final moved = await _validateAndMove(f, filename, expectedSize, expectedSha256);
        if (moved != null) return moved;
      }
    }
    return null;
  }

  Future<File?> _validateAndMove(File tmp, String filename, int expectedSize, String expectedSha256) async {
    if (!await tmp.exists()) return null;

    final sz = await tmp.length();
    if (sz != expectedSize) {
      await tmp.delete().catchError((_) {});
      return null;
    }

    final digest = await sha256.bind(tmp.openRead()).first;
    final got = digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toLowerCase();
    if (got != expectedSha256.toLowerCase()) {
      await tmp.delete().catchError((_) {});
      return null;
    }

    final dir = await getModelsDir();
    final dest = File(p.join(dir.path, filename));
    await dest.parent.create(recursive: true);
    if (await dest.exists()) await dest.delete();
    await tmp.rename(dest.path);
    return dest;
  }

  static Future<String> modelsDirPath() async {
    final dir = await getModelsDir();
    return dir.path;
  }
}

