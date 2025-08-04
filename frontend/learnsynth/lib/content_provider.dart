import 'dart:io';

import 'package:flutter/foundation.dart';

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
  final List<ContentItem> _saved = [];

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

  /// Optional helper to retrieve saved content from storage if the list
  /// is empty. The current implementation simply acts as a placeholder
  /// for future persistence logic.
  Future<void> fetchSavedContentIfNeeded() async {
    if (_saved.isEmpty) {
      // TODO: load items from local storage or backend
    }
  }
}
