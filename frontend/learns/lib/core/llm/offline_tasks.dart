import 'dart:async';
import 'dart:convert';
import 'llm_provider.dart';

const _summarizeTpl =
    'You are a tutor. Summarize into 5 bullet points, simple Spanish:\n\n{section}';
const _flashTpl =
    'Crea 4 flashcards en JSON estricto como lista de objetos con llaves "q" y "a". '
    'Solo usa este texto y responde en español. Texto:\n\n{section}';

Future<String> offlineSummarize(LLMProvider llm, String text) async {
  final buf = StringBuffer();
  await for (final t
      in llm.stream(_summarizeTpl.replaceFirst('{section}', text))) {
    buf.write(t);
  }
  return buf.toString().trim();
}

Future<List<Map<String, String>>> offlineFlashcards(
    LLMProvider llm, String text) async {
  final buf = StringBuffer();
  await for (final t in llm.stream(
      _flashTpl.replaceFirst('{section}', text),
      maxTokens: 256,
      temperature: .2)) {
    buf.write(t);
  }
  final raw = buf.toString();
  try {
    final parsed = jsonDecode(raw);
    if (parsed is List) {
      return parsed.map<Map<String, String>>((e) {
        final m = (e as Map).map((k, v) => MapEntry('$k', '$v'));
        return {'q': m['q'] ?? '', 'a': m['a'] ?? ''};
      }).toList();
    }
  } catch (_) {}
  final lines =
      raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
  final out = <Map<String, String>>[];
  for (final l in lines.take(4)) {
    out.add({'q': l.trim(), 'a': 'Respuesta no estructurada'});
  }
  return out;
}

