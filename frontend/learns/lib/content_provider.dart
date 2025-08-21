import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum StudyMode { memorization, deep_understanding, contextual_association, interactive_evaluation }

class ContentProvider extends ChangeNotifier {
  String? _content;          // processed text used across the study flow (the transcript)
  String? _raw;              // raw text (optional)
  String? _error;
  bool _analyzing = false;
  Map<String, dynamic>? _studyPack;

  // Getters:
  String? get content => _content;
  String? get raw => _raw;
  bool get analyzing => _analyzing;
  String? get error => _error;
  Map<String, dynamic>? get studyPack => _studyPack;

  void clear() {
    _content = null;
    _raw = null;
    _error = null;
    _studyPack = null;
    _analyzing = false;
    notifyListeners();
  }

  void setTranscript(String text) {
    _content = text;
    _error = null;
    notifyListeners();
  }

  Map<String, dynamic> _normalizePack(dynamic decoded) {
    // If backend returned a List, wrap it:
    if (decoded is List) return {'items': decoded};

    // If backend returned a Map, but 'data' is a List, lift it to 'items'
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final data = map['data'];
      if (data is List) {
        return {
          ...map,
          'items': data,
        };
      }
      return map;
    }
    // Fallback: coerce to text
    return {'text': decoded?.toString() ?? ''};
  }

  Future<void> runAnalysis({required StudyMode mode}) async {
    if (_content == null || _content!.trim().isEmpty) return;

    _analyzing = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('http://localhost:8000/analyze');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': _content, 'mode': mode.name}),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
        _studyPack = _normalizePack(decoded);
      } else {
        _error = 'Analysis failed (${resp.statusCode})';
      }
    } catch (e) {
      _error = 'Analysis error: $e';
    } finally {
      _analyzing = false;
      notifyListeners();
    }
  }

  String safeString(Map<String, dynamic> m, String key) =>
      (m[key] is String) ? (m[key] as String) : '';

  List<dynamic> safeList(Map<String, dynamic> m, String key) =>
      (m[key] is List) ? (m[key] as List) : const [];
}
