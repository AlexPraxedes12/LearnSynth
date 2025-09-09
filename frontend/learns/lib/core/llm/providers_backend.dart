import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llm_router.dart';
import '../net/backend_client.dart';
import '../net/api_config.dart';

Stream<String> backendSSEStream(String base, String prompt, {int maxTokens = 256, double temperature = .2}) async* {
  final req = http.Request('POST', Uri.parse('$base/llm/generate'))
    ..headers['Content-Type'] = 'application/json'
    ..body = jsonEncode({
      'prompt': prompt,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': true,
      'target_questions': '8-12',
      'max_flashcards': 10,
      'mini_tasks': 'Pasos con checkpoints y auto-reflexión breve cada 3-4 pasos',
    });
  final resp = await BackendClient.client.send(req).timeout(ApiConfig.backendTimeout);
  if (resp.statusCode >= 400) {
    final body = await resp.stream.bytesToString();
    throw Exception('Backend error ${resp.statusCode}: $body');
  }
  final dec = resp.stream.transform(utf8.decoder);
  await for (final chunk in dec) {
    for (final line in const LineSplitter().convert(chunk)) {
      if (!line.startsWith('data: ')) continue;
      final data = line.substring(6);
      if (data == '[DONE]') return;
      final m = jsonDecode(data);
      if (m['error'] != null) throw Exception(m['error']);
      final d = m['delta'];
      if (d is String && d.isNotEmpty) yield d;
    }
  }
}

class BackendLLMProvider implements LLMProvider {
  @override String get id => 'backend';
  final String base;
  BackendLLMProvider(this.base);

  @override
  Stream<String> stream(String prompt, {int maxTokens = 256, double temperature = .2}) {
    return backendSSEStream(base, prompt, maxTokens: maxTokens, temperature: temperature);
  }
}
