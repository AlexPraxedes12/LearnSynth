import 'dart:async';
import 'dart:math';
import 'llm_router.dart';

class HeuristicOfflineLLMProvider implements LLMProvider {
  @override
  String get id => 'heuristic';

  @override
  Stream<String> stream(String prompt, {int maxTokens = 256, double temperature = .2}) async* {
    final text = prompt.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) {
      yield 'Texto vacío.';
      return;
    }

    final sentences = _splitSentences(text);
    final scored = _scoreSentences(sentences);
    final top = _topK(scored, k: 5).map((i) => sentences[i]).toList();

    final keywords = _topKeywords(text, n: 12);
    final clozes = _makeCloze(sentences, n: 4);

    final out = StringBuffer()
      ..writeln('### Resumen (heurístico)\n- ${top.join('\n- ')}\n')
      ..writeln('### Palabras clave\n${keywords.map((e) => "• $e").join("\n")}\n')
      ..writeln('### Cloze (completa los huecos)\n${clozes.join("\n")}');

    final s = out.toString();
    for (final chunk in _chunk(s, 64)) {
      yield chunk;
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }

  Future<List<Map<String, String>>> generateFlashcards(String text) async {
    final keywords = _topKeywords(text, n: 12);
    final sentences = _splitSentences(text);
    final fallback = sentences.isNotEmpty ? sentences.first : '';
    return keywords.map((k) {
      final def = sentences.firstWhere(
        (s) => s.toLowerCase().contains(k.toLowerCase()),
        orElse: () => fallback,
      );
      return {'term': k, 'definition': def.trim()};
    }).toList(growable: false);
  }

  Future<Map<String, dynamic>> generateConceptGraph(String text) async {
    final keywords = _topKeywords(text, n: 8);
    final nodes = [
      {'id': 'Topics', 'label': 'Topics'},
      ...keywords.map((k) => {'id': k, 'label': k}),
    ];
    final relations = <Map<String, String>>[];
    for (final k in keywords) {
      relations.add({'sourceId': 'Topics', 'targetId': k});
    }
    for (var i = 0; i < keywords.length - 1; i++) {
      relations.add({'sourceId': keywords[i], 'targetId': keywords[i + 1]});
    }
    return {
      'groups': [
        {'title': 'Topics', 'topics': keywords}
      ],
      'nodes': nodes,
      'relations': relations,
    };
  }

  Future<List<Map<String, dynamic>>> generateQuiz(String text) async {
    final keywords = _topKeywords(text, n: 4);
    final rand = Random();
    return keywords.map((k) {
      final options = [...keywords]..shuffle(rand);
      final answerIndex = options.indexOf(k);
      return {
        'question': 'Select the term related to "$k"',
        'options': options,
        'answerIndex': answerIndex,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> generateCloze(String text) async {
    final sentences = _splitSentences(text);
    final rand = Random();
    final items = <Map<String, dynamic>>[];
    final keywords = _topKeywords(text, n: 8);
    for (final s in sentences.where((s) => s.length > 60).take(4)) {
      final words = s.split(' ');
      final idx = (words.length / 2).floor();
      if (idx < 0 || idx >= words.length) continue;
      final answer = words[idx]
          .replaceAll(RegExp(r'[^\wáéíóúüñ]'), '');
      if (answer.length < 4) continue;
      words[idx] = '____';
      final distractors = (keywords.where((w) => w != answer).toList()
            ..shuffle(rand))
          .take(3)
          .toList();
      final options = [...distractors, answer]..shuffle(rand);
      items.add({
        'sentence': '• ${words.join(' ')}',
        'options': options,
        'answerIndex': options.indexOf(answer),
      });
    }
    return items;
  }

  Future<List<Map<String, String>>> generateDeepPrompts(String text) async {
    final keywords = _topKeywords(text, n: 4);
    final main = keywords.isNotEmpty ? keywords.first : 'the topic';
    return [
      {
        'prompt': 'What is the main concept discussed in this material?',
        'hint': main,
      },
      {
        'prompt': 'How do the key ideas relate to each other?',
        'hint': keywords.length > 1
            ? 'They connect concepts like ${keywords.join(', ')}.'
            : 'They build on each other.',
      },
      {
        'prompt': 'What are the practical applications of these concepts?',
        'hint': 'Consider how $main can be used in practice.',
      },
      {
        'prompt': 'Explain the significance of $main',
        'hint': '$main is significant because it is central to the topic.',
      },
    ];
  }

  List<String> _splitSentences(String t) =>
      t.split(RegExp(r'(?<=[.!?])\s+')).where((s) => s.trim().length > 3).toList();

  Map<int, double> _scoreSentences(List<String> sents) {
    final scores = <int, double>{};
    final tf = <String, int>{};
    for (final s in sents) {
      for (final w in s.toLowerCase().split(RegExp(r'[^a-záéíóúüñ0-9]+'))) {
        if (w.length < 3) continue;
        tf[w] = (tf[w] ?? 0) + 1;
      }
    }
    for (var i = 0; i < sents.length; i++) {
      final len = sents[i].length.clamp(1, 500);
      var sum = 0.0;
      for (final w in sents[i].toLowerCase().split(RegExp(r'[^a-záéíóúüñ0-9]+'))) {
        if (w.length < 3) continue;
        sum += (tf[w] ?? 0).toDouble();
      }
      scores[i] = sum / len;
    }
    return scores;
  }

  Iterable<int> _topK(Map<int, double> scores, {int k = 5}) =>
      scores.keys.toList()
        ..sort((a, b) => scores[b]!.compareTo(scores[a]!))
        ..length = scores.length < k ? scores.length : k;

  List<String> _topKeywords(String text, {int n = 8}) {
    final counts = <String, int>{};
    for (final w in text.toLowerCase().split(RegExp(r'[^a-záéíóúüñ0-9]+'))) {
      if (w.length < 4) continue;
      counts[w] = (counts[w] ?? 0) + 1;
    }
    final items = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return items.take(n).toList();
  }

  List<String> _makeCloze(List<String> sents, {int n = 4}) {
    final out = <String>[];
    for (final s in sents.where((s) => s.length > 60).take(n)) {
      final words = s.split(' ');
      final idx = (words.length / 2).floor();
      if (idx >= 0 && idx < words.length) {
        final hide = words[idx].replaceAll(RegExp(r'[^\wáéíóúüñ]'), '');
        if (hide.length >= 4) {
          words[idx] = '____';
          out.add('• ${words.join(' ')}  (pista: ${hide[0]}...)');
        }
      }
    }
    return out.isEmpty
        ? ['• (No se pudo generar cloze con el texto dado)']
        : out;
  }

  Iterable<String> _chunk(String s, int n) sync* {
    for (var i = 0; i < s.length; i += n) {
      yield s.substring(i, i + n > s.length ? s.length : i + n);
    }
  }
}
