import 'dart:convert';
import '../net/api_config.dart';
import 'local_backend.dart';
import 'package:http/http.dart' as http;
import '../net/backend_client.dart';

class ReplicateBackend implements LlmBackend {
  ReplicateBackend({String? base}) : base = base ?? ApiConfig.apiBase;
  final String base;

  @override
  Future<void> init() async {}

  @override
  Future<String> generate(String prompt, {int maxTokens = 128}) async {
    final req = http.Request('POST', Uri.parse('$base/llm/generate'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'prompt': prompt,
        'max_tokens': maxTokens,
        'temperature': 0.2,
        'stream': false,
        'target_questions': '8-12',
        'max_flashcards': 10,
        'mini_tasks': 'Pasos con checkpoints y auto-reflexión breve cada 3-4 pasos',
      });
    final resp = await BackendClient.client.send(req).timeout(ApiConfig.backendTimeout);
    if (resp.statusCode >= 400) {
      final body = await resp.stream.bytesToString();
      throw Exception('Backend error ${resp.statusCode}: $body');
    }
    final body = await resp.stream.bytesToString();
    final data = jsonDecode(body);
    return data['output']?.toString() ?? '';
  }

  @override
  Future<void> dispose() async {}
}
