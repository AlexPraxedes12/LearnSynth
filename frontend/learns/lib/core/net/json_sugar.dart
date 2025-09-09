import 'dart:convert';

Map<String, dynamic> mapifyResponse(String body) {
  final dynamic j = jsonDecode(body);
  // Caso 1: respuesta correcta (objeto)
  if (j is Map<String, dynamic>) {
    final dp = j['deep_prompts'];
    final list = (dp is List) ? dp : (dp == null ? const [] : [dp]);
    return {...j, 'deep_prompts': list};
  }
  // Caso 2: lista "sueltas" (p.ej. prompts)
  if (j is List) {
    return {
      'ok': true,
      'transcript': '',
      'summary': '',
      'tags': const <String>[],
      'deep_prompts': j,
    };
  }
  // Caso 3: un número o string solo -> inválido pero legible
  return {'ok': false, 'error': 'Invalid JSON shape: ${j.runtimeType}'};
}
