// Copied from the upstream repository. Defines named route strings used
// throughout the app. Keeping route definitions in a single place
// prevents typos and makes refactoring easier.
class Routes {
  static const String home = '/';
  static const String textInput = '/text-input';
  static const String loading = '/loading';
  static const String studyPack = '/studyPack';
  static const String analysis = studyPack;
  static const String methodSelection = '/method-selection';
  static const String deepUnderstanding = '/deep';
  static const String memorization = '/memorization';
  static const String contextualAssociation = '/concept';
  static const String quiz = '/quiz';
  static const String interactiveEvaluation = quiz;
  static const String progress = '/progress';
  static const String addContent = '/add-content';
  static const String pdfPicker = '/pdf-picker';
  static const String audio = '/audio';
  static const String videoPicker = '/video-picker';
  static const String library = '/library';
}

class AppRoutes {
  static const String analyzing = '/analyzing';
  static const String studyPack = '/studyPack';
}
