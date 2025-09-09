import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:learnsynth_offline_llm/learnsynth_offline_llm.dart'
    if (dart.library.html) 'package:learnsynth/stub_web.dart';

abstract class LlmBackend {
  Future<void> init();
  Future<String> generate(String prompt, {int maxTokens = 128});
  Future<void> dispose();
}

class LocalBackend implements LlmBackend {
  LocalBackend(this.modelPath, {LearnsynthOfflineLlm? plugin})
      : _plugin = plugin ?? LearnsynthOfflineLlm();

  final String modelPath;
  final LearnsynthOfflineLlm _plugin;

  bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isWindows);

  @override
  Future<void> init() async {
    if (!_supported) {
      throw UnsupportedError('Offline LLM not supported on this platform');
    }
    await _plugin.loadModel(modelPath);
  }

  @override
  Future<String> generate(String prompt, {int maxTokens = 128}) {
    if (!_supported) {
      throw UnsupportedError('Offline LLM not supported on this platform');
    }
    return _plugin.generate(prompt, maxTokens: maxTokens);
  }

  @override
  Future<void> dispose() async {
    if (!_supported) return;
    await _plugin.freeModel();
  }
}
