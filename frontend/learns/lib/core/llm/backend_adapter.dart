import 'dart:convert';
import '../net/api_config.dart';
import '../net/json_sugar.dart';
import '../net/backend_client.dart';
import 'analyze_result.dart';
import 'llm_adapter.dart';
import 'response_parser.dart';

class BackendAdapter implements LlmAdapter {
  BackendAdapter({String? base}) : base = base ?? ApiConfig.apiBase;
  final String base;

  @override
  ProviderCapabilities get caps =>
      const ProviderCapabilities(supportsJson: true, maxTokens: 4096);

  @override
  Future<AnalyzeResult> analyze(String input) async {
    final uri = Uri.parse('$base/analyze');
    final resp = await BackendClient.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': input, 'mode': 'memorization'}));
    final bodyText = utf8.decode(resp.bodyBytes);
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: $bodyText');
    }
    final j = mapifyResponse(bodyText);
    j['deep_prompts'] = coercePrompts(j['deep_prompts']);
    return AnalyzeResult.fromJson(j);
  }

  @override
  Future<StudyPack> buildPack(String text) async {
    final uri = Uri.parse('$base/build-pack');
    final resp = await BackendClient.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}));
    final bodyText = utf8.decode(resp.bodyBytes);
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}: $bodyText');
    }
    final j = jsonDecode(bodyText) as Map<String, dynamic>;
    return StudyPack.fromJson(j);
  }
}
