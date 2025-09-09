import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'learnsynth_offline_llm_method_channel.dart';

abstract class LearnsynthOfflineLlmPlatform extends PlatformInterface {
  LearnsynthOfflineLlmPlatform() : super(token: _token);

  static final Object _token = Object();

  static LearnsynthOfflineLlmPlatform _instance = MethodChannelLearnsynthOfflineLlm();

  static LearnsynthOfflineLlmPlatform get instance => _instance;

  static set instance(LearnsynthOfflineLlmPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> loadModel(String modelPath) {
    throw UnimplementedError('loadModel() has not been implemented.');
  }

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
  }) {
    throw UnimplementedError('generate() has not been implemented.');
  }

  Future<void> freeModel() {
    throw UnimplementedError('freeModel() has not been implemented.');
  }

  Future<String> status() {
    throw UnimplementedError('status() has not been implemented.');
  }
}
