import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llm_provider.dart';
import '../net/backend_client.dart';
import '../net/api_config.dart';

class GptOssReplicateProvider implements LLMProvider {
  final String apiToken; // inyectar vía Settings/Secrets
  GptOssReplicateProvider(this.apiToken);

  @override
  String get id => "replicate";

  @override
  Future<bool> health() async => apiToken.isNotEmpty;

  @override
  Stream<String> stream(String prompt,
      {int maxTokens = 256, double temperature = .2}) async* {
    // Implementación mínima (polling o streaming) según tu backend/endpoint en Replicate.
    // Dejar TODO con esqueleto claro para que luego completes con tu endpoint real.
    final uri = Uri.parse(
        "https://api.replicate.com/v1/models/openai/gpt-oss-20b/predictions");
    final req = await BackendClient.client
        .post(
          uri,
          headers: {
            'Authorization': 'Token $apiToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "input": {
              "prompt": prompt,
              "max_tokens": maxTokens,
              "temperature": temperature,
              "stream": false // si tienes streaming, activar y procesar SSE
            }
          }),
        )
        .timeout(ApiConfig.backendTimeout);
    if (req.statusCode >= 400) {
      throw Exception("Replicate error ${req.statusCode}: ${req.body}");
    }
    final data = jsonDecode(req.body);
    final out = data["output"]?.toString() ?? data["logs"]?.toString() ?? "";
    // Emitir en un solo bloque por ahora (sin SSE); luego sustituir por streaming real.
    for (final ch in out.split('')) {
      yield ch;
      await Future.delayed(const Duration(milliseconds: 5));
    }
  }
}
