import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum StudyMode {
  memorization,
  deep_understanding,
  contextual_association,
  interactive_evaluation,
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
  // ---------------------------------------------------------------------------
  // Core text/analysis state
  // ---------------------------------------------------------------------------

  /// Cleaned or processed content used throughout the study flow (transcript)
  String? transcript;

  /// Raw text before any processing (can mirror transcript for now)
  String? rawText;

  /// Normalized analysis result (summary, topics, flashcards, quiz, etc.)
  Map<String, dynamic>? analysis;

  /// Busy flag for running analysis
  bool isAnalyzing = false;

  /// Error message from analysis/transcription
  String? error;

  // ---------------------------------------------------------------------------
  // Legacy fields kept for wider app compatibility
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Legacy getters to remain compatible with older code
  // ---------------------------------------------------------------------------
  String? get content => transcript;
  String? get raw => rawText;
  bool get analyzing => isAnalyzing;
  Map<String, dynamic>? get studyPack => analysis;
  List<ContentItem> get savedContent => List.unmodifiable(_saved);

  bool get hasTranscript => (transcript != null && transcript!.trim().isNotEmpty);

  // ---------------------------------------------------------------------------
  // Content management helpers
  // ---------------------------------------------------------------------------
  void setContent(String value) {
    setTranscript(value);
    filePath = null;
    _saved.add(ContentItem(content: value));
    notifyListeners();
  }

  /// Update transcript/rawText after transcription completes.
  void setTranscript(String value) {
    transcript = value;
    rawText = value;
    error = null;
    notifyListeners();
  }

  void setPdfPath(String path) {
    filePath = path;
    transcript = null;
    _saved.add(ContentItem(filePath: path));
    notifyListeners();
  }

  void setAudioPath(String path) {
    filePath = path;
    transcript = null;
    _saved.add(ContentItem(filePath: path));
    notifyListeners();
  }

  /// Store an audio [file]. Useful when a recording or picker returns
  /// a [File] object instead of just a path.
  void setAudioFile(File file) {
    filePath = file.path;
    transcript = null;
    _saved.add(ContentItem(filePath: file.path));
    notifyListeners();
  }

  void setVideoPath(String path) {
    filePath = path;
    transcript = null;
    _saved.add(ContentItem(filePath: path));
    notifyListeners();
  }

  /// Store both [path] and [content] for the same content item.
  /// The raw text is kept in [rawText] so it can be processed later.
  void setFileContent({required String path, required String content}) {
    rawText = content;
    transcript = content;
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

  // ---------------------------------------------------------------------------
  // New methods for transcript analysis
  // ---------------------------------------------------------------------------

  void clear() {
    transcript = null;
    rawText = null;
    error = null;
    analysis = null;
    isAnalyzing = false;
    notifyListeners();
  }

  /// Normalize backend responses to a stable shape.
  /// Handles:
  /// - { ...fields } or { data: { ...fields } } or [ { ...fields } ]
  /// - summary: string? or nested
  /// - topics: list?
  Map<String, dynamic> _normalize(dynamic json) {
    dynamic root = json;

    if (root is Map && root['data'] != null) {
      root = root['data'];
    }
    if (root is List && root.isNotEmpty) {
      root = root.first;
    }
    if (root is! Map) {
      return <String, dynamic>{};
    }

    final map = Map<String, dynamic>.from(root);

    final summaryNorm = map['summary'] is String
        ? map['summary'] as String
        : (map['summary']?.toString() ?? '');
    final topicsRaw = map['topics'];
    final topicsNorm = (topicsRaw is List)
        ? topicsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return <String, dynamic>{
      ...map,
      'summary': summaryNorm,
      'topics': topicsNorm,
    };
  }

  /// Calls the backend to analyze the text and stores a normalized result.
  Future<void> runAnalysis({String baseUrl = 'http://10.0.2.2:8000'}) async {
    final payloadText = (rawText?.trim().isNotEmpty ?? false)
        ? rawText!.trim()
        : (transcript ?? '').trim();

    if (payloadText.isEmpty) {
      // nothing to analyze
      return;
    }

    isAnalyzing = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$baseUrl/analyze');
      final resp = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'text': payloadText}),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        analysis = _normalize(decoded);
        summary = analysis?['summary'] as String? ?? '';
        topics = (analysis?['topics'] as List?)?.map((e) => e.toString()).toList() ?? [];
        notifyListeners();
      } else {
        throw Exception('Analyze failed: ${resp.statusCode} ${resp.body}');
      }
    } finally {
      isAnalyzing = false;
      notifyListeners();
    }
  }
}
