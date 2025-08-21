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
  /// Cleaned or processed content used throughout the study flow.
  String? content;

  /// Raw text extracted from uploaded files before any processing.
  String? rawText;

  String? filePath;
  String? summary;
  List<String> topics = [];
  List<Map<String, String>> flashcards = [];
  Map<String, dynamic>? conceptMap;
  List<Map<String, dynamic>> contextualExercises = [];
  List<Map<String, dynamic>> evaluationQuestions = [];
  Map<String, String> activitySummaries = {};

  /// Cached statistics about the user's study progress.
  Map<String, dynamic> progress = {};
  final List<ContentItem> _saved = [];

  /// Transcription and analysis state
  String? transcript;
  StudyMode mode = StudyMode.memorization;
  Map<String, dynamic>? _studyPack;
  Map<String, dynamic>? get studyPack => _studyPack;
  bool loading = false;
  String? error;

  /// List of all content pieces added by the user.
  List<ContentItem> get savedContent => List.unmodifiable(_saved);

  void setContent(String value) {
    content = value;
    rawText = value;
    filePath = null;
    _saved.add(ContentItem(content: value));
    notifyListeners();
  }

  void setPdfPath(String path) {
    filePath = path;
    content = null;
    _saved.add(ContentItem(filePath: path));
    notifyListeners();
  }

  void setAudioPath(String path) {
    filePath = path;
    content = null;
    _saved.add(ContentItem(filePath: path));
    notifyListeners();
  }

  /// Store an audio [file]. Useful when a recording or picker returns
  /// a [File] object instead of just a path.
  void setAudioFile(File file) {
    filePath = file.path;
    content = null;
    _saved.add(ContentItem(filePath: file.path));
    notifyListeners();
  }

  void setVideoPath(String path) {
    filePath = path;
    content = null;
    _saved.add(ContentItem(filePath: path));
    notifyListeners();
  }

  /// Store both [path] and [content] for the same content item.
  /// The raw text is kept in [rawText] so it can be processed later.
  void setFileContent({required String path, required String content}) {
    rawText = content;
    this.content = content;
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

  // --- New methods for transcript analysis ---
  void setTranscript(String t) {
    transcript = t;
    content = t;
    notifyListeners();
  }

  void setMode(StudyMode m) {
    mode = m;
    notifyListeners();
  }

  Future<void> runAnalysis() async {
    final t = transcript?.trim();
    if (t == null || t.isEmpty) {
      error = 'No transcript available';
      notifyListeners();
      return;
    }
    loading = true;
    error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('http://10.0.2.2:8000/analyze');
      final resp = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': t, 'mode': mode.name}));
      if (resp.statusCode != 200) {
        throw FormatException(
            'Analyze failed (${resp.statusCode}): ${resp.body}');
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(resp.body);
      } catch (e) {
        throw FormatException('Invalid JSON: ${e.toString()}');
      }

      if (decoded is List) {
        if (decoded.isEmpty) {
          throw const FormatException('Empty array response');
        }
        decoded = decoded.first;
      }

      if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is Map) {
          decoded = Map<String, dynamic>.from(decoded['data'] as Map);
        } else {
          decoded = Map<String, dynamic>.from(decoded);
        }
      } else {
        throw FormatException('Unexpected response type: ${decoded.runtimeType}');
      }

      _studyPack = decoded;
      summary = decoded['summary'] as String?;
      flashcards = (decoded['flashcards'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map<Map<String, String>>((e) =>
                  e.map((key, value) => MapEntry(key, value.toString())))
              .toList() ??
          [];
      evaluationQuestions =
          (decoded['quiz'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      conceptMap = decoded['concept_map'] as Map<String, dynamic>?;
      contextualExercises =
          (decoded['contextual_association'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
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
}

