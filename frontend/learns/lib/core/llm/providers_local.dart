import 'package:learnsynth/services/offline_llm_compat.dart';
import 'llm_router.dart';

class LocalOfflineLLMProvider implements LLMProvider {
  @override
  String get id => 'offline';

  @override
  Stream<String> stream(String prompt,
      {int maxTokens = 256, double temperature = .2}) async* {
    if (!OfflineLLM.instance.isReady) {
      await OfflineLLM.instance.init();
    }
    yield* OfflineLLM.instance.stream(prompt, maxTokens: maxTokens);
  }
}
