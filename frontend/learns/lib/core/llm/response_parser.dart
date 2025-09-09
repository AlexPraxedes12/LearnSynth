import 'dart:convert';

Map<String, dynamic>? extractFirstJsonObject(String s) {
  final start = s.indexOf('{');
  if (start == -1) return null;
  var depth = 0;
  for (var i = start; i < s.length; i++) {
    final c = s[i];
    if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0) {
        final sub = s.substring(start, i + 1);
        try {
          final j = jsonDecode(sub);
          if (j is Map<String, dynamic>) return j;
        } catch (_) {
          return null;
        }
      }
    }
  }
  return null;
}

List<Map<String, String>> coercePrompts(dynamic raw) {
  final list = <Map<String, String>>[];
  if (raw is List) {
    for (final item in raw) {
      if (item is Map) {
        final p = (item['prompt'] ?? item['text'] ?? item['question'] ?? '')
            .toString()
            .trim();
        final h = (item['hint'] ?? item['explanation'] ?? '')
            .toString()
            .trim();
        if (p.isNotEmpty) list.add({'prompt': p, 'hint': h});
      } else {
        final p = item.toString().trim();
        if (p.isNotEmpty) list.add({'prompt': p, 'hint': ''});
      }
    }
  } else if (raw is Map) {
    final p = (raw['prompt'] ?? raw['text'] ?? raw['question'] ?? '')
        .toString()
        .trim();
    final h =
        (raw['hint'] ?? raw['explanation'] ?? '').toString().trim();
    if (p.isNotEmpty) list.add({'prompt': p, 'hint': h});
  } else if (raw != null) {
    final p = raw.toString().trim();
    if (p.isNotEmpty) list.add({'prompt': p, 'hint': ''});
  }
  return list;
}
