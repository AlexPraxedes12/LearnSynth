import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class TranscriptionService {
  // Android emulator host:
  final Uri _endpoint = Uri.parse('http://10.0.2.2:8000/upload-content');

  Future<String> sendFile(File f) async {
    try {
      final req = http.MultipartRequest('POST', _endpoint)
        ..files.add(await http.MultipartFile.fromPath('file', f.path));
      final res = await req.send().timeout(const Duration(minutes: 2));
      final body = await res.stream.bytesToString();

      if (res.statusCode != 200) {
        return 'Error: HTTP ${res.statusCode}: $body';
      }

      final map = jsonDecode(body) as Map<String, dynamic>;
      final txt = (map['text'] ?? '').toString();
      if (txt.trim().isNotEmpty) return txt;

      // For non-audio/video responses (e.g., course JSON), return raw JSON text
      return jsonEncode(map);
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Calls the backend to analyze a block of [text] and returns the parsed JSON
  // response. Throws an [Exception] if the request fails.
  Future<Map<String, dynamic>> analyzeText(String text,
      {String mode = 'memorization'}) async {
    final uri = Uri.parse('http://10.0.2.2:8000/analyze');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text, 'mode': mode}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Analyze failed (${resp.statusCode}): ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
