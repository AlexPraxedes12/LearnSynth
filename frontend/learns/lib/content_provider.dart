import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum StudyMode {
  memorization,
  deep_understanding,
  contextual_association,
  interactive_evaluation
}

/// Simple model representing a piece of study content. Either [content]
/// or [filePath] will be provided depending on how the content was
/// added.
class ContentItem {
  final String? content;
  final String? filePath;
  const ContentItem({this.content, this.filePath});
}

/// Stores the content added by the user so it can be accessed across screens.
class ContentProvider extends ChangeNotifier {
  // --- Core text/analysis state ---
  String? _content; // processed text used across the study flow (the transcript)
  String? _raw; // raw text (optional)
  String? _error;
  bool _analyzing = false;
  Map<String, dynamic>? _studyPack;

  // --- Legacy fields kept for wider app compatibility ---
  String? filePath;
  String? summary;
  List<String> topics = [];
  List<Map<String, String>> flashcards = [];
  Map<String, dynamic>? conceptMap;
  List<Map<String, dynamic>> contextualExercises = [];
  List<Map<String, dynamic>> evaluationQuestions = [];
  Map<String, String> activitySummaries = {};
  Map<String, dynamic> progress = {};
  final List<ContentItem> _saved = [];

  // Getters
  String? get content => _content;
  String? get raw => _raw;
  bool get analyzing => _analyzing;
  String? get error => _error;
  Map<String, dynamic>? get studyPack => _studyPack;
  List<ContentItem> get savedContent => List.unmodifiable(_saved);

  // --- Content management helpers (legacy) ---
  void setContent(String value) {
    _content = value;
    _raw = value;
    filePath = null;
    _saved.add(ContentItem(content: value));
    notifyListeners();
  }

  void setPdfPath(String path) {
    filePath = path;
    _content = null;
    _saved.add(ContentItem(filePath: path));
    notifyListeners();
  }

  void setAudioPath(String path) {
    filePath = path;
    _content = null;
    _saved.add(ContentItem(filePath: path));
    notifyListeners();
  }

  /// Store an audio [file]. Useful when a recording or picker returns
  /// a [File] object instead of just a path.
  void setAudioFile(File file) {
    filePath = file.path;
    _content = null;
    _saved.add(ContentItem(filePath: file.path));
    notifyListeners();
  }

  void setVideoPath(String path) {
    filePath = path;
    _content = null;
    _saved.add(ContentItem(filePath: path));
    notifyListeners();
  }

  /// Store both [path] and [content] for the same content item.
  /// The raw text is kept in [_raw] so it can be processed later.
  void setFileContent({required String path, required String content}) {
    _raw = content;
    _content = content;
    filePath = path;
    final index = _saved.lastIndexWhere((item) => item.filePath == path);
    final item = ContentItem(content: content, filePath: path);
    if (index != -1) {
      _saved[index] = item;
    } else {
      _saved.add(item);
    }
    notifyListeners();
  }

  void setAnalysis(String summaryText, List<String> topicsList) {
    summary = summaryText;
    topics = topicsList;
    notifyListeners();
  }

  void setFlashcards(List<Map<String, String>> cards) {
    flashcards = cards;
    notifyListeners();
  }

  void setConceptMap(Map<String, dynamic> map) {
    conceptMap = map;
    notifyListeners();
  }

  void setContextualExercises(List<Map<String, dynamic>> list) {
    contextualExercises = list;
    notifyListeners();
  }

  void setEvaluationQuestions(List<Map<String, dynamic>> list) {
    evaluationQuestions = list;
    notifyListeners();
  }

  void setActivitySummaries(Map<String, String> summaries) {
    activitySummaries = summaries;
    notifyListeners();
  }

  /// Update the locally cached [progress] data.
  void setProgress(Map<String, dynamic> prog) {
    progress = prog;
    notifyListeners();
  }

  /// Optional helper to retrieve saved content from storage if the list
  /// is empty. The current implementation simply acts as a placeholder
  /// for future persistence logic.
  Future<void> fetchSavedContentIfNeeded() async {
    if (_saved.isEmpty) {
      // TODO: load items from local storage or backend
    }
  }

  // --- New methods for transcript analysis ---

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

