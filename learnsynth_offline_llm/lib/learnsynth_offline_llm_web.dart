import 'dart:async';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'learnsynth_offline_llm_platform_interface.dart';

class LearnsynthOfflineLlmWeb extends LearnsynthOfflineLlmPlatform {
  static void registerWith(Registrar registrar) {
    LearnsynthOfflineLlmPlatform.instance = LearnsynthOfflineLlmWeb();
  }

  @override
  Future<bool> loadModel(String modelPath) async => false;

  @override
  Future<String> status() async => 'web_unsupported';

  @override
  Future<void> freeModel() async {}

  @override
  Future<String> generate(
    String prompt, {
    int maxTokens = 64,
    String? systemPrompt,
    double temperature = 0.6,
    double topP = 0.9,
    int topK = 40,
    double repeatPenalty = 1.10,
    int repeatLastN = 64,
    int seed = 1234,
  }) async {
    throw UnsupportedError('learnsynth_offline_llm: Web not supported');
  }
}
