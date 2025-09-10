import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../util/platform_cap.dart';

import 'local_backend.dart';
import 'replicate_backend.dart';
import 'models_fs.dart' if (dart.library.html) 'models_fs_stub.dart';
import 'model_download.dart';
import 'llm_adapter.dart';
import 'backend_adapter.dart';
import 'local_adapter.dart';
import 'analyze_result.dart';
import 'package:learnsynth/config/env.dart';

/// Modes for selecting the LLM backend.
enum BackendMode { replicate, local }

/// Servicio simple para generar texto usando diferentes backends.
class LlmService extends ChangeNotifier {
  LlmService._();
  static final LlmService I = LlmService._();

  LlmBackend? _backend;
  LlmAdapter? _adapter;
  SharedPreferences? _prefs;
  BackendMode _mode = BackendMode.replicate;
  String? _modelPath;
  bool _busy = false;
  Future<String>? _inFlight;
  final _catalog = ModelCatalog();
  final _downloader = ModelDownloader();

  /// Nombre del modo actual.
  String get mode => _mode.name;

  bool get busy => _busy;

  /// Obtiene el catálogo de modelos desde el manifest.
  Future<List<ModelInfo>> getCatalog() => _catalog.fetch();

  Future<String> getModelsDirPath() => ModelDownloader.modelsDirPath();

  /// Nombres de archivos .gguf instalados en el directorio de modelos (lowercase).
  Future<Set<String>> installedFilenames() async {
    final dir = await getModelsDir();
    final out = <String>{};
    await for (final e in dir.list(followLinks: false)) {
      if (e is File && e.path.toLowerCase().endsWith('.gguf')) {
        out.add(p.basename(e.path).toLowerCase());
      }
    }
    return out;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final modeStr = _prefs!.getString('llm_mode');
    if (modeStr != null) {
      _mode = BackendMode.values.firstWhere(
        (e) => e.name == modeStr,
        orElse: () => BackendMode.replicate,
      );
    }
    _modelPath = _prefs!.getString('llm_model_path');
    if (!Env.enableOfflineLLM ||
        !caps.supportsLocalLlm ||
        (caps.isAndroid && !(await caps.isPhysicalDevice))) {
      await setMode(BackendMode.replicate);
    } else {
      await setMode(_mode);
    }
  }

  Future<bool> ensureLocalModelSelected() async {
    if (!Env.enableOfflineLLM) return false;
    if (_modelPath != null && File(_modelPath!).existsSync()) return true;

    final f = await pickInstalledModel();
    if (f != null) {
      _modelPath = f.path;
      _backend = LocalBackend(_modelPath!);
      _adapter = null;
      await _prefs?.setString('llm_model_path', _modelPath!);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> setMode(BackendMode m) async {
    if (m == BackendMode.local) {
      final physical = caps.isAndroid ? await caps.isPhysicalDevice : false;
      if (!Env.enableOfflineLLM || !caps.supportsLocalLlm || !physical) {
        _mode = BackendMode.replicate;
        await _prefs?.setString('llm_mode', _mode.name);
        notifyListeners();
        return;
      }
    }

    _mode = m;
    await _prefs?.setString('llm_mode', m.name);

    if (m == BackendMode.local) {
      final ok = await ensureLocalModelSelected();
      if (!ok) {
        _backend = null; // no hay modelo aún; la UI ofrecerá descarga
      }
    } else {
      _backend = ReplicateBackend();
    }
    _adapter = null;
    notifyListeners();
  }

  /// Carga el modelo local si corresponde.
  Future<bool> loadLocalIfNeeded() async {
    if (!Env.enableOfflineLLM) return false;
    if (_mode != BackendMode.local || _modelPath == null) return false;
    _backend ??= LocalBackend(_modelPath!);
    await _backend!.init();
    return true;
  }

  /// Devuelve el estado del modelo local.
  Future<(bool installed, String label)> localState() async {
    if (!Env.enableOfflineLLM) {
      return (false, 'Offline LLM disabled');
    }
    final f = await pickInstalledModel();
    if (f == null) return (false, 'No instalado');
    final size = await f.length();
    return (true, '${p.basename(f.path)} • ${humanSize(size)}');
  }

  /// Descarga por ID del manifest, guarda en /files/models, persiste y (si está en modo local) carga el modelo.
  Future<bool> downloadAndSelectById(
    String modelId, {
    void Function(double p)? onProgress,
  }) async {
    if (!Env.enableOfflineLLM) {
      throw UnsupportedError('Offline LLM disabled');
    }
    final models = await _catalog.fetch();
    final m = models.firstWhere(
      (x) => x.id == modelId,
      orElse: () => throw Exception('Modelo no encontrado: $modelId'),
    );

    final file = await _downloader.downloadModel(
      filename: m.name,
      mirrors: m.mirrors,
      expectedSha256: m.sha256,
      expectedSize: m.sizeBytes,
      onProgress: onProgress,
    );
    if (file == null) return false;

    await _prefs?.setString('llm_model_path', file.path);
    _modelPath = file.path;

    if (_mode == BackendMode.local) {
      await _backend?.dispose();
      _backend = LocalBackend(_modelPath!);
      await _backend?.init();
      _adapter = null;
      notifyListeners();
      return true;
    } else {
      notifyListeners();
      return true;
    }
  }

  /// Selecciona y (si está en modo local) carga un modelo ya instalado por nombre de archivo.
  Future<bool> selectAndLoadInstalled(String filename) async {
    if (!Env.enableOfflineLLM) {
      throw UnsupportedError('Offline LLM disabled');
    }
    final dir = await getModelsDir();
    final path = p.join(dir.path, filename);
    final f = File(path);
    if (!await f.exists()) return false;

    await _prefs?.setString('llm_model_path', path);
    _modelPath = path;

    if (_mode == BackendMode.local) {
      await _backend?.dispose();
      _backend = LocalBackend(_modelPath!);
      await _backend?.init();
      _adapter = null;
      notifyListeners();
      return true;
    } else {
      notifyListeners();
      return true;
    }
  }

  /// Re-detecta un .gguf ya presente y lo carga si estás en modo local.
  Future<bool> rescanAndLoadExisting() async {
    if (!Env.enableOfflineLLM) return false;
    final ok =
        await ensureLocalModelSelected(); // tu método actual de autodetección
    if (!ok) return false;
    if (_mode == BackendMode.local) {
      await _backend?.dispose();
      _backend = LocalBackend(_modelPath!);
      await _backend?.init();
      _adapter = null;
      notifyListeners();
      return true;
    }
    notifyListeners();
    return true;
  }

  /// Genera una respuesta completa a partir de [prompt].
  Future<String> generate(String prompt, {int maxTokens = 128}) async {
    while (_busy) {
      await _inFlight;
    }
    _busy = true;
    notifyListeners();
    final future = () async {
      if (_mode == BackendMode.local) {
        await loadLocalIfNeeded();
      } else {
        await _backend?.init();
      }
      return _backend!.generate(prompt, maxTokens: maxTokens);
    }();
    _inFlight = future;
    try {
      return await future;
    } finally {
      _busy = false;
      _inFlight = null;
      notifyListeners();
    }
  }

  Future<LlmAdapter> _ensureAdapter() async {
    if (_adapter != null) return _adapter!;
    if (_mode == BackendMode.local) {
      await loadLocalIfNeeded();
      _adapter = LocalAdapter(_backend!);
    } else {
      _adapter = BackendAdapter();
    }
    return _adapter!;
  }

  Future<(AnalyzeResult, StudyPack)> analyze(String text) async {
    final ad = await _ensureAdapter();
    final res = await ad.analyze(text);
    final base = res.summary.isNotEmpty ? res.summary : res.transcript;
    final pack = await ad.buildPack(base.isNotEmpty ? base : text);
    return (res, pack);
  }
}
