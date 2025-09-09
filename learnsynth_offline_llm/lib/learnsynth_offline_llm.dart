import 'learnsynth_offline_llm_platform_interface.dart';

class LearnsynthOfflineLlm {
  // --- Singleton backing ---
  // Private constructor for singleton implementation.
  LearnsynthOfflineLlm._();

  // Single shared instance of [LearnsynthOfflineLlm].
  static final LearnsynthOfflineLlm instance = LearnsynthOfflineLlm._();

  /// Factory que retorna la instancia única del plugin.
  factory LearnsynthOfflineLlm() => instance;

  Future<bool> loadModel(String modelPath) =>
      LearnsynthOfflineLlmPlatform.instance.loadModel(modelPath);

  Future<void> freeModel() =>
      LearnsynthOfflineLlmPlatform.instance.freeModel();

  Future<String> status() =>
      LearnsynthOfflineLlmPlatform.instance.status();

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
  }) =>
      LearnsynthOfflineLlmPlatform.instance.generate(
        prompt,
        maxTokens: maxTokens,
        systemPrompt: systemPrompt,
        temperature: temperature,
        topP: topP,
        topK: topK,
        repeatPenalty: repeatPenalty,
        repeatLastN: repeatLastN,
        seed: seed,
      );
}
