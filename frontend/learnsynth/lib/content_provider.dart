import 'package:flutter/foundation.dart';

/// Stores the content added by the user so it can be accessed across screens.
class ContentProvider extends ChangeNotifier {
  String? text;
  String? filePath;

  void setText(String value) {
    text = value;
    filePath = null;
    notifyListeners();
  }

  void setPdfPath(String path) {
    filePath = path;
    text = null;
    notifyListeners();
  }

  void setAudioPath(String path) {
    filePath = path;
    text = null;
    notifyListeners();
  }

  void setVideoPath(String path) {
    filePath = path;
    text = null;
    notifyListeners();
  }
}
