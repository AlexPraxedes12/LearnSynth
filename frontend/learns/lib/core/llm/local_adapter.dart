import 'analyze_result.dart';
import 'llm_adapter.dart';
import 'prompt_pack.dart';
import 'response_parser.dart';
import 'local_backend.dart';
import 'providers_heuristic.dart';

class LocalAdapter implements LlmAdapter {
  LocalAdapter(this.backend, {HeuristicOfflineLLMProvider? heuristic})
      : _heuristic = heuristic ?? HeuristicOfflineLLMProvider();

  final LlmBackend backend;
  final HeuristicOfflineLLMProvider _heuristic;

  @override
  ProviderCapabilities get caps =>
      const ProviderCapabilities(supportsJson: false, maxTokens: 512);

  @override
  Future<AnalyzeResult> analyze(String input) async {
    final prompt = PromptPack.analyze(input);
    final raw = await backend.generate(prompt, maxTokens: caps.maxTokens);
    final j = extractFirstJsonObject(raw);
    if (j != null) {
      j['deep_prompts'] = coercePrompts(j['deep_prompts']);
      return AnalyzeResult.fromJson(j);
    }
    return AnalyzeResult(
      transcript: input,
      summary: '',
      tags: const [],
      deepPrompts: const [],
    );
  }

  @override
  Future<StudyPack> buildPack(String text) async {
    final flash = await _heuristic.generateFlashcards(text);
    final graph = await _heuristic.generateConceptGraph(text);
    final quiz = await _heuristic.generateQuiz(text);
    final cloze = await _heuristic.generateCloze(text);
    return StudyPack.fromJson({
      'flashcards': flash,
      'concept_groups': graph['groups'],
      'quiz': quiz,
      'cloze': cloze,
    });
  }
}
