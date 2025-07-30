import 'package:flutter/foundation.dart';

/// Simple model representing a piece of study content. Either [text]
/// or [filePath] will be provided depending on how the content was
/// added.
class ContentItem {
  final String? text;
  final String? filePath;
  const ContentItem({this.text, this.filePath});
}

/// Stores the content added by the user so it can be accessed across screens.
class ContentProvider extends ChangeNotifier {
  String? text;
  String? filePath;
  String? summary;
  List<String> topics = [];
  List<Map<String, String>> flashcards = [];
  Map<String, dynamic>? conceptMap;
  List<Map<String, dynamic>> exercises = [];
  final List<ContentItem> _saved = [];

  /// List of all content pieces added by the user.
  List<ContentItem> get savedContent => List.unmodifiable(_saved);

  void setText(String value) {
    text = value;
    filePath = null;
    _saved.add(ContentItem(text: value));
    notifyListeners();
  }

  void setPdfPath(String path) {
    filePath = path;
    text = null;
    _saved.add(ContentItem(filePath: path));
    notifyListeners();
  }

  void setAudioPath(String path) {
    filePath = path;
    text = null;
    _saved.add(ContentItem(filePath: path));
    notifyListeners();
  }

  void setVideoPath(String path) {
    filePath = path;
    text = null;
    _saved.add(ContentItem(filePath: path));
    notifyListeners();
  }

  /// Store both [path] and [text] for the same content item.
  void setFileContent({required String path, required String text}) {
    this.text = text;
    filePath = path;
    final index = _saved.lastIndexWhere((item) => item.filePath == path);
    final item = ContentItem(text: text, filePath: path);
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

  void setExercises(List<Map<String, dynamic>> list) {
    exercises = list;
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
