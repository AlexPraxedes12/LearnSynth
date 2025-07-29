import 'dart:convert';
import 'package:http/http.dart' as http;

class ContentService {
  static const String _baseUrl = 'http://10.0.2.2:8000';

  static Future<String> uploadContent(String text) async {
    final url = Uri.parse('$_baseUrl/upload-content');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['text'] as String? ?? '';
    } else {
      throw Exception('Failed to upload content');
    }
  }
}
