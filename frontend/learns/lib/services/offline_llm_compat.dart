import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:learnsynth_offline_llm/learnsynth_offline_llm.dart'
    if (dart.library.html) 'package:learnsynth/stub_web.dart';
import '../config/env.dart';

/// Wrapper de compatibilidad para código legado que usa OfflineLLM con:
/// - init(String modelPath)
/// - isReady
/// - stream(String prompt, {int maxTokens})
/// - unload()
/// Internamente delega al plugin nuevo LearnsynthOfflineLlm.
class OfflineLLM {
  OfflineLLM._();
  static final OfflineLLM _instance = OfflineLLM._();

  /// Soporta ambos estilos: OfflineLLM.instance y OfflineLLM()
  factory OfflineLLM() => _instance;
  static OfflineLLM get instance => _instance;

  static const String _defaultModelId = 'qwen25-1_5b-q4km';
  static const String defaultModelId = _defaultModelId;

  bool _isReady = false;
  bool get isReady => _isReady;

  /// Antes: init(modelPath) -> ahora delega a loadModel() usando un [modelId].
  /// El parámetro es opcional para ocultar detalles de rutas al resto de la app.
  bool get _supported =>
      Env.enableOfflineLLM && !kIsWeb && (Platform.isAndroid || Platform.isWindows);

  Future<bool> init([String modelId = _defaultModelId]) async {
    if (!_supported) return false;
    final modelPath =
        'packages/learnsynth_offline_llm/assets/models/$modelId';
    final ok = await LearnsynthOfflineLlm.instance.loadModel(modelPath);
    _isReady = ok;
    return ok;
  }

  Future<String> generate(String prompt, {int maxTokens = 64}) {
    if (!_supported) {
      throw UnsupportedError('Offline LLM not supported on this platform');
    }
    return LearnsynthOfflineLlm.instance
        .generate(prompt, maxTokens: maxTokens);
  }

  /// Stream de compat: emite todo el texto en un solo chunk.
  /// Si tu UI esperaba tokens sueltos, usa asTokens:true para dividir por espacios.
  Stream<String> stream(String prompt,
      {int maxTokens = 64, bool asTokens = false}) async* {
    final text = await generate(prompt, maxTokens: maxTokens);
    if (asTokens) {
      final re = RegExp(r'\s+');
      for (final t in text.split(re)) {
        if (t.isNotEmpty) yield t;
      }
    } else {
      yield text;
    }
  }

  Future<void> unload() async {
    if (!_supported) return;
    await LearnsynthOfflineLlm.instance.freeModel();
    _isReady = false;
  }

  Future<String> status() {
    if (!_supported) {
      return Future.value('unsupported');
    }
    return LearnsynthOfflineLlm.instance.status();
  }
}
