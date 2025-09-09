import 'package:test/test.dart';
import 'package:learnsynth/core/llm/providers_heuristic.dart';

void main() {
  const sampleText =
      'Artificial intelligence is the simulation of human intelligence processes by machines. '
      'Machine learning allows systems to learn from data and improve over time. '
      'Deep learning is a subset of machine learning focused on neural networks.';
  final provider = HeuristicOfflineLLMProvider();

  test('flashcards have definitions', () async {
    final cards = await provider.generateFlashcards(sampleText);
    expect(cards, isNotEmpty);
    expect(
        cards.every((c) =>
            (c['term'] ?? '').toString().isNotEmpty &&
            (c['definition'] ?? '').toString().isNotEmpty),
        isTrue);
  });

  test('concept graph has nodes and relations', () async {
    final graph = await provider.generateConceptGraph(sampleText);
    final groups = graph['groups'] as List;
    final nodes = graph['nodes'] as List;
    final rels = graph['relations'] as List;
    expect(groups.isNotEmpty, isTrue);
    expect(nodes.isNotEmpty, isTrue);
    expect(rels.isNotEmpty, isTrue);
    expect(
        rels.every((r) =>
            (r['sourceId'] ?? '').toString().isNotEmpty &&
            (r['targetId'] ?? '').toString().isNotEmpty),
        isTrue);
  });

  test('cloze items include options and valid answer', () async {
    final items = await provider.generateCloze(sampleText);
    expect(items.isNotEmpty, isTrue);
    expect(
        items.every((i) {
          final opts = i['options'] as List;
          final ans = i['answerIndex'] as int;
          return opts.isNotEmpty && ans >= 0 && ans < opts.length;
        }),
        isTrue);
  });

  test('deep prompts include question and hint', () async {
    final prompts = await provider.generateDeepPrompts(sampleText);
    expect(prompts.isNotEmpty, isTrue);
    expect(
        prompts.every((p) =>
            (p['prompt'] ?? '').toString().isNotEmpty &&
            (p['hint'] ?? '').toString().isNotEmpty),
        isTrue);
  });
}
