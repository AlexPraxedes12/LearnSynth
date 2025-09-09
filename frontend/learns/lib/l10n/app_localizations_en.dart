// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get add => 'Add';

  @override
  String get progress => 'Progress';

  @override
  String get library => 'Library';

  @override
  String get addContent => 'Add Content';

  @override
  String get pasteText => 'Paste Text';

  @override
  String get pasteTextDesc => 'Type or paste plain text.';

  @override
  String get uploadPdf => 'Upload PDF';

  @override
  String get uploadPdfDesc => 'Pick a PDF document to analyse.';

  @override
  String get uploadAudio => 'Upload Audio';

  @override
  String get uploadAudioDesc => 'Pick an audio file for transcription.';

  @override
  String get uploadVideo => 'Upload Video';

  @override
  String get uploadVideoDesc => 'Select a video for transcription.';

  @override
  String get analyzingTitle => 'Analyzing';

  @override
  String get analyzingDots => 'Analyzing…';

  @override
  String get analyzeFailed => 'Analyze failed. Please try again.';

  @override
  String get uploadDocument => 'Upload Document';

  @override
  String get selectPdf => 'Select PDF';

  @override
  String get chooseAudio => 'Choose Audio';

  @override
  String get chooseVideo => 'Choose Video';

  @override
  String get fileTooLarge => 'File exceeds 100 MB';

  @override
  String get maxUploadSize => 'Maximum file size: 100 MB';

  @override
  String get studyPack => 'Study Pack';

  @override
  String get summary => 'Summary';

  @override
  String get memorizationFlashcards => 'Memorization (Flashcards)';

  @override
  String get deepUnderstanding => 'Deep Understanding';

  @override
  String get contextualAssociation => 'Contextual Association';

  @override
  String get interactiveEvaluation => 'Interactive Evaluation (Quiz)';

  @override
  String get clozeDrills => 'Cloze Drills (Fill-in-the-Blank)';

  @override
  String get save => 'Save';

  @override
  String get savedToLibrary => 'Saved to Library';

  @override
  String get progressTrackingNotImplemented => 'Progress tracking not implemented';

  @override
  String get importJson => 'Import JSON';

  @override
  String get noContentYet => 'No content yet';

  @override
  String exportedTo(Object path) {
    return 'Exported to $path';
  }

  @override
  String get deletePackQuestion => 'Delete Pack?';

  @override
  String get deletePackWarning => 'This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get export => 'Export';

  @override
  String get rename => 'Rename';

  @override
  String get renameCourse => 'Rename course';

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String get addTextTitle => 'Add Text';

  @override
  String get enterTextHint => 'Enter or paste text here';

  @override
  String get continueLabel => 'Continue';

  @override
  String get noDeepPrompts => 'No deep prompts available.';

  @override
  String get back => 'Back';

  @override
  String get hideHint => 'Hide hint';

  @override
  String get showHint => 'Show hint';

  @override
  String get prev => 'Prev';

  @override
  String get next => 'Next';

  @override
  String get finish => 'Finish';

  @override
  String get flashcardsTitle => 'Flashcards';

  @override
  String get noFlashcards => 'No flashcards available';

  @override
  String get term => 'Term';

  @override
  String get definition => 'Definition';

  @override
  String get conceptMapTitle => 'Concept Map';

  @override
  String get noConceptMap => 'No concept map available';

  @override
  String get topics => 'Topics';

  @override
  String get clozeDrillsTitle => 'Cloze Drills';

  @override
  String get showExplanation => 'Show explanation';

  @override
  String get answer => 'Answer';

  @override
  String get results => 'Results';

  @override
  String score(Object score, Object total) {
    return 'Score: $score / $total';
  }

  @override
  String get close => 'Close';

  @override
  String get quizTitle => 'Quiz';

  @override
  String questionOf(Object current, Object total) {
    return 'Question $current of $total';
  }

  @override
  String get overallProgress => 'Overall Progress';

  @override
  String get methodProgress => 'Method Progress';

  @override
  String get studyTime => 'Study Time';

  @override
  String get sessions => 'Sessions';

  @override
  String get packs => 'Packs';

  @override
  String get memorization => 'Memorization';

  @override
  String get conceptMap => 'Concept Map';

  @override
  String get quiz => 'Quiz';

  @override
  String get recentStudyPacks => 'Recent Study Packs';

  @override
  String get startStudyingMessage => 'Start studying to see your progress';

  @override
  String transcriptionFailed(Object error) {
    return 'Transcription failed: $error';
  }

  @override
  String get analysisFailed => 'Analysis failed';

  @override
  String get selectAudio => 'Select Audio';

  @override
  String get transcribingDots => 'Transcribing…';

  @override
  String get transcribe => 'Transcribe';

  @override
  String get unableToAnalyze => 'Unable to analyze';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get french => 'French';
}
