import 'analyze_result.dart';

class StudyPack {
  final List<Map<String, dynamic>> flashcards;
  final List<Map<String, dynamic>> conceptGroups;
  final List<Map<String, dynamic>> quiz;
  final List<Map<String, dynamic>> cloze;

  const StudyPack({
    required this.flashcards,
    required this.conceptGroups,
    required this.quiz,
    required this.cloze,
  });

  factory StudyPack.empty() => const StudyPack(
        flashcards: [],
        conceptGroups: [],
        quiz: [],
        cloze: [],
      );

  factory StudyPack.fromJson(Map<String, dynamic> j) => StudyPack(
        flashcards: ((j['flashcards'] as List?) ?? const [])
            .cast<Map<String, dynamic>>(),
        conceptGroups: ((j['concept_groups'] ?? j['conceptGroups'] ?? []) as List)
            .cast<Map<String, dynamic>>(),
        quiz:
            ((j['quiz'] ?? j['quizzes'] ?? []) as List).cast<Map<String, dynamic>>(),
        cloze: ((j['cloze'] as List?) ?? const [])
            .cast<Map<String, dynamic>>(),
      );
}

class ProviderCapabilities {
  final bool supportsJson;
  final int maxTokens;
  const ProviderCapabilities({
    required this.supportsJson,
    required this.maxTokens,
  });
}

abstract class LlmAdapter {
  ProviderCapabilities get caps;
  Future<AnalyzeResult> analyze(String input);
  Future<StudyPack> buildPack(String text);
}
