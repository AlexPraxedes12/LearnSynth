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

  void setAnalysis(String summaryText, List<String> topicsList) {
    summary = summaryText;
    topics = topicsList;
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
