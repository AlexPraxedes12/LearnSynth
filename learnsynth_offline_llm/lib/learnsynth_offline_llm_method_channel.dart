import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'learnsynth_offline_llm_platform_interface.dart';

class MethodChannelLearnsynthOfflineLlm extends LearnsynthOfflineLlmPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('learnsynth_offline_llm');

  @override
  Future<bool> loadModel(String modelPath) async {
    final ok = await methodChannel.invokeMethod<bool>('loadModel', {
      'path': modelPath,    // clave usada en Kotlin
      'model': modelPath,   // compat
    });
    return ok ?? false;
  }

  @override
  Future<String> status() async {
    return await methodChannel.invokeMethod<String>('status') ?? 'idle';
  }

  @override
  Future<void> freeModel() async {
    await methodChannel.invokeMethod('free');
  }

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
    final args = <String, Object?>{
      'prompt': prompt,
      'maxTokens': maxTokens,
      'system': systemPrompt,
      'temp': temperature,
      'topP': topP,
      'topK': topK,
      'repeatPenalty': repeatPenalty,
      'repeatLastN': repeatLastN,
      'seed': seed,
    };
    return await methodChannel.invokeMethod<String>('generate', args) ?? '';
  }
}
