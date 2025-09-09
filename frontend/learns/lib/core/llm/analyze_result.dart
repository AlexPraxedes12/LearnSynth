class AnalyzeResult {
  final String transcript;
  final String summary;
  final List<String> tags;
  final List<Map<String, String>> deepPrompts;

  AnalyzeResult({
    required this.transcript,
    required this.summary,
    required this.tags,
    required this.deepPrompts,
  });

  factory AnalyzeResult.fromJson(Map<String, dynamic> j) {
    final List raw = (j['deep_prompts'] as List?) ?? const [];
    final dps = <Map<String, String>>[];
    for (final item in raw) {
      if (item is Map) {
        final p = (item['prompt'] ?? item['text'] ?? item['question'] ?? '')
            .toString()
            .trim();
        final h = (item['hint'] ?? item['explanation'] ?? '')
            .toString()
            .trim();
        if (p.isNotEmpty) {
          dps.add({'prompt': p, 'hint': h});
        }
      } else {
        final p = item.toString().trim();
        if (p.isNotEmpty) dps.add({'prompt': p, 'hint': ''});
      }
    }
    return AnalyzeResult(
      transcript: (j['transcript'] ?? '').toString(),
      summary: (j['summary'] ?? '').toString(),
      tags: ((j['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      deepPrompts: dps,
    );
  }
}
