import 'dart:io' show Directory, File, Platform;
export 'dart:io' show File, Directory;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const kModelsFolderName = 'models';
const kMinModelBytes = 10 * 1024 * 1024; // 10 MB umbral
const kPreferredNames = <String>[
  'Qwen2.5-1.5B-Instruct-Q4_K_M.gguf',
  'TinyLlama-1.1b-chat-v1.0.Q4_K_M.gguf',
];

Future<String> getModelsDirectory() async {
  if (kIsWeb) {
    throw UnsupportedError('Offline models not supported on web');
  }

  if (Platform.isAndroid) {
    final ext = await getExternalStorageDirectory();
    return p.join(ext!.path, kModelsFolderName);
  } else if (Platform.isWindows) {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'LearnSynth', kModelsFolderName);
  } else {
    throw UnsupportedError('Platform not supported for offline models');
  }
}

Future<Directory> getModelsDir() async {
  final path = await getModelsDirectory();
  final dir = Directory(path);
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

Future<File?> pickInstalledModel({List<String> preferred = kPreferredNames}) async {
  final dir = await getModelsDir();

  // 1) preferidos exactos
  for (final name in preferred) {
    final f = File(p.join(dir.path, name));
    if (await f.exists() && (await f.length()) >= kMinModelBytes) return f;
  }

  // 2) cualquier .gguf válido (el más grande primero)
  final entries = await dir.list().toList();
  final ggufs = <File>[];
  for (final e in entries) {
    if (e is File && e.path.toLowerCase().endsWith('.gguf')) {
      try {
        final sz = await e.length();
        if (sz >= kMinModelBytes) ggufs.add(e);
      } catch (_) {}
    }
  }
  ggufs.sort((a, b) => b.lengthSync().compareTo(a.lengthSync()));
  return ggufs.isNotEmpty ? ggufs.first : null;
}

String humanSize(int bytes) {
  const k = 1024.0;
  final mb = bytes / (k * k);
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  final gb = mb / 1024.0;
  return '${gb.toStringAsFixed(2)} GB';
}

