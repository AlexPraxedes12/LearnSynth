import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr')
  ];

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @addContent.
  ///
  /// In en, this message translates to:
  /// **'Add Content'**
  String get addContent;

  /// No description provided for @pasteText.
  ///
  /// In en, this message translates to:
  /// **'Paste Text'**
  String get pasteText;

  /// No description provided for @pasteTextDesc.
  ///
  /// In en, this message translates to:
  /// **'Type or paste plain text.'**
  String get pasteTextDesc;

  /// No description provided for @uploadPdf.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF'**
  String get uploadPdf;

  /// No description provided for @uploadPdfDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick a PDF document to analyse.'**
  String get uploadPdfDesc;

  /// No description provided for @uploadAudio.
  ///
  /// In en, this message translates to:
  /// **'Upload Audio'**
  String get uploadAudio;

  /// No description provided for @uploadAudioDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick an audio file for transcription.'**
  String get uploadAudioDesc;

  /// No description provided for @uploadVideo.
  ///
  /// In en, this message translates to:
  /// **'Upload Video'**
  String get uploadVideo;

  /// No description provided for @uploadVideoDesc.
  ///
  /// In en, this message translates to:
  /// **'Select a video for transcription.'**
  String get uploadVideoDesc;

  /// No description provided for @analyzingTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyzing'**
  String get analyzingTitle;

  /// No description provided for @analyzingDots.
  ///
  /// In en, this message translates to:
  /// **'Analyzing…'**
  String get analyzingDots;

  /// No description provided for @analyzeFailed.
  ///
  /// In en, this message translates to:
  /// **'Analyze failed. Please try again.'**
  String get analyzeFailed;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @selectPdf.
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get selectPdf;

  /// No description provided for @chooseAudio.
  ///
  /// In en, this message translates to:
  /// **'Choose Audio'**
  String get chooseAudio;

  /// No description provided for @chooseVideo.
  ///
  /// In en, this message translates to:
  /// **'Choose Video'**
  String get chooseVideo;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File exceeds 100 MB'**
  String get fileTooLarge;

  /// No description provided for @maxUploadSize.
  ///
  /// In en, this message translates to:
  /// **'Maximum file size: 100 MB'**
  String get maxUploadSize;

  /// No description provided for @studyPack.
  ///
  /// In en, this message translates to:
  /// **'Study Pack'**
  String get studyPack;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @memorizationFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Memorization (Flashcards)'**
  String get memorizationFlashcards;

  /// No description provided for @deepUnderstanding.
  ///
  /// In en, this message translates to:
  /// **'Deep Understanding'**
  String get deepUnderstanding;

  /// No description provided for @contextualAssociation.
  ///
  /// In en, this message translates to:
  /// **'Contextual Association'**
  String get contextualAssociation;

  /// No description provided for @interactiveEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Interactive Evaluation (Quiz)'**
  String get interactiveEvaluation;

  /// No description provided for @clozeDrills.
  ///
  /// In en, this message translates to:
  /// **'Cloze Drills (Fill-in-the-Blank)'**
  String get clozeDrills;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @savedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Saved to Library'**
  String get savedToLibrary;

  /// No description provided for @progressTrackingNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Progress tracking not implemented'**
  String get progressTrackingNotImplemented;

  /// No description provided for @importJson.
  ///
  /// In en, this message translates to:
  /// **'Import JSON'**
  String get importJson;

  /// No description provided for @noContentYet.
  ///
  /// In en, this message translates to:
  /// **'No content yet'**
  String get noContentYet;

  /// No description provided for @exportedTo.
  ///
  /// In en, this message translates to:
  /// **'Exported to {path}'**
  String exportedTo(Object path);

  /// No description provided for @deletePackQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Pack?'**
  String get deletePackQuestion;

  /// No description provided for @deletePackWarning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deletePackWarning;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renameCourse.
  ///
  /// In en, this message translates to:
  /// **'Rename course'**
  String get renameCourse;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @addTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Text'**
  String get addTextTitle;

  /// No description provided for @enterTextHint.
  ///
  /// In en, this message translates to:
  /// **'Enter or paste text here'**
  String get enterTextHint;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @noDeepPrompts.
  ///
  /// In en, this message translates to:
  /// **'No deep prompts available.'**
  String get noDeepPrompts;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @hideHint.
  ///
  /// In en, this message translates to:
  /// **'Hide hint'**
  String get hideHint;

  /// No description provided for @showHint.
  ///
  /// In en, this message translates to:
  /// **'Show hint'**
  String get showHint;

  /// No description provided for @prev.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get prev;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @flashcardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Flashcards'**
  String get flashcardsTitle;

  /// No description provided for @noFlashcards.
  ///
  /// In en, this message translates to:
  /// **'No flashcards available'**
  String get noFlashcards;

  /// No description provided for @term.
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get term;

  /// No description provided for @definition.
  ///
  /// In en, this message translates to:
  /// **'Definition'**
  String get definition;

  /// No description provided for @conceptMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Concept Map'**
  String get conceptMapTitle;

  /// No description provided for @noConceptMap.
  ///
  /// In en, this message translates to:
  /// **'No concept map available'**
  String get noConceptMap;

  /// No description provided for @topics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topics;

  /// No description provided for @clozeDrillsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloze Drills'**
  String get clozeDrillsTitle;

  /// No description provided for @showExplanation.
  ///
  /// In en, this message translates to:
  /// **'Show explanation'**
  String get showExplanation;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score: {score} / {total}'**
  String score(Object score, Object total);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @quizTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizTitle;

  /// No description provided for @questionOf.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionOf(Object current, Object total);

  /// No description provided for @overallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get overallProgress;

  /// No description provided for @methodProgress.
  ///
  /// In en, this message translates to:
  /// **'Method Progress'**
  String get methodProgress;

  /// No description provided for @studyTime.
  ///
  /// In en, this message translates to:
  /// **'Study Time'**
  String get studyTime;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @packs.
  ///
  /// In en, this message translates to:
  /// **'Packs'**
  String get packs;

  /// No description provided for @memorization.
  ///
  /// In en, this message translates to:
  /// **'Memorization'**
  String get memorization;

  /// No description provided for @conceptMap.
  ///
  /// In en, this message translates to:
  /// **'Concept Map'**
  String get conceptMap;

  /// No description provided for @quiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quiz;

  /// No description provided for @recentStudyPacks.
  ///
  /// In en, this message translates to:
  /// **'Recent Study Packs'**
  String get recentStudyPacks;

  /// No description provided for @startStudyingMessage.
  ///
  /// In en, this message translates to:
  /// **'Start studying to see your progress'**
  String get startStudyingMessage;

  /// No description provided for @transcriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Transcription failed: {error}'**
  String transcriptionFailed(Object error);

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed'**
  String get analysisFailed;

  /// No description provided for @selectAudio.
  ///
  /// In en, this message translates to:
  /// **'Select Audio'**
  String get selectAudio;

  /// No description provided for @transcribingDots.
  ///
  /// In en, this message translates to:
  /// **'Transcribing…'**
  String get transcribingDots;

  /// No description provided for @transcribe.
  ///
  /// In en, this message translates to:
  /// **'Transcribe'**
  String get transcribe;

  /// No description provided for @unableToAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Unable to analyze'**
  String get unableToAnalyze;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
