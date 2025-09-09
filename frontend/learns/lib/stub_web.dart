class LearnsynthOfflineLlm {
  LearnsynthOfflineLlm._();
  static final LearnsynthOfflineLlm instance = LearnsynthOfflineLlm._();
  factory LearnsynthOfflineLlm() => instance;

  Future<bool> loadModel(String modelPath) async {
    throw UnsupportedError('Offline LLM not supported on web');
  }

  Future<void> freeModel() async {
    throw UnsupportedError('Offline LLM not supported on web');
  }

  Future<String> status() async => 'web_unsupported';

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
    throw UnsupportedError('Offline LLM not supported on web');
  }
}
