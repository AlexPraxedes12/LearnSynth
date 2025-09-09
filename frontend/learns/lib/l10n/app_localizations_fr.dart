// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get add => 'Ajouter';

  @override
  String get progress => 'Progression';

  @override
  String get library => 'Bibliothèque';

  @override
  String get addContent => 'Ajouter du contenu';

  @override
  String get pasteText => 'Coller du texte';

  @override
  String get pasteTextDesc => 'Tapez ou collez du texte simple.';

  @override
  String get uploadPdf => 'Téléverser PDF';

  @override
  String get uploadPdfDesc => 'Choisissez un document PDF à analyser.';

  @override
  String get uploadAudio => 'Téléverser audio';

  @override
  String get uploadAudioDesc => 'Choisissez un fichier audio pour la transcription.';

  @override
  String get uploadVideo => 'Téléverser vidéo';

  @override
  String get uploadVideoDesc => 'Sélectionnez une vidéo pour la transcription.';

  @override
  String get analyzingTitle => 'Analyse en cours';

  @override
  String get analyzingDots => 'Analyse…';

  @override
  String get analyzeFailed => 'Échec de l\'analyse. Veuillez réessayer.';

  @override
  String get uploadDocument => 'Téléverser document';

  @override
  String get selectPdf => 'Sélectionner PDF';

  @override
  String get chooseAudio => 'Choisir audio';

  @override
  String get chooseVideo => 'Choisir vidéo';

  @override
  String get fileTooLarge => 'Le fichier dépasse 100 Mo';

  @override
  String get maxUploadSize => 'Taille maximale : 100 Mo';

  @override
  String get studyPack => 'Pack d\'étude';

  @override
  String get summary => 'Résumé';

  @override
  String get memorizationFlashcards => 'Mémorisation (flashcards)';

  @override
  String get deepUnderstanding => 'Compréhension approfondie';

  @override
  String get contextualAssociation => 'Association contextuelle';

  @override
  String get interactiveEvaluation => 'Évaluation interactive (quiz)';

  @override
  String get clozeDrills => 'Exercices de trous';

  @override
  String get save => 'Enregistrer';

  @override
  String get savedToLibrary => 'Enregistré dans la bibliothèque';

  @override
  String get progressTrackingNotImplemented => 'Suivi de progression non implémenté';

  @override
  String get importJson => 'Importer JSON';

  @override
  String get noContentYet => 'Pas encore de contenu';

  @override
  String exportedTo(Object path) {
    return 'Exporté vers $path';
  }

  @override
  String get deletePackQuestion => 'Supprimer le pack ?';

  @override
  String get deletePackWarning => 'Cette action est irréversible.';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get export => 'Exporter';

  @override
  String get rename => 'Renommer';

  @override
  String get renameCourse => 'Renommer le cours';

  @override
  String get nameCannotBeEmpty => 'Le nom ne peut pas être vide';

  @override
  String get addTextTitle => 'Ajouter du texte';

  @override
  String get enterTextHint => 'Saisissez ou collez du texte ici';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get noDeepPrompts => 'Aucune invite approfondie disponible.';

  @override
  String get back => 'Retour';

  @override
  String get hideHint => 'Masquer l\'indice';

  @override
  String get showHint => 'Afficher l\'indice';

  @override
  String get prev => 'Précédent';

  @override
  String get next => 'Suivant';

  @override
  String get finish => 'Terminer';

  @override
  String get flashcardsTitle => 'Flashcards';

  @override
  String get noFlashcards => 'Aucune carte disponible';

  @override
  String get term => 'Terme';

  @override
  String get definition => 'Définition';

  @override
  String get conceptMapTitle => 'Carte conceptuelle';

  @override
  String get noConceptMap => 'Aucune carte conceptuelle disponible';

  @override
  String get topics => 'Sujets';

  @override
  String get clozeDrillsTitle => 'Exercices à trous';

  @override
  String get showExplanation => 'Afficher l\'explication';

  @override
  String get answer => 'Réponse';

  @override
  String get results => 'Résultats';

  @override
  String score(Object score, Object total) {
    return 'Score : $score / $total';
  }

  @override
  String get close => 'Fermer';

  @override
  String get quizTitle => 'Quiz';

  @override
  String questionOf(Object current, Object total) {
    return 'Question $current sur $total';
  }

  @override
  String get overallProgress => 'Progression globale';

  @override
  String get methodProgress => 'Progression de la méthode';

  @override
  String get studyTime => 'Temps d\'étude';

  @override
  String get sessions => 'Sessions';

  @override
  String get packs => 'Packs';

  @override
  String get memorization => 'Mémorisation';

  @override
  String get conceptMap => 'Carte conceptuelle';

  @override
  String get quiz => 'Quiz';

  @override
  String get recentStudyPacks => 'Packs d\'étude récents';

  @override
  String get startStudyingMessage => 'Commencez à étudier pour voir vos progrès';

  @override
  String transcriptionFailed(Object error) {
    return 'La transcription a échoué : $error';
  }

  @override
  String get analysisFailed => 'L\'analyse a échoué';

  @override
  String get selectAudio => 'Sélectionner audio';

  @override
  String get transcribingDots => 'Transcription…';

  @override
  String get transcribe => 'Transcrire';

  @override
  String get unableToAnalyze => 'Impossible d\'analyser';

  @override
  String get settings => 'Paramètres';

  @override
  String get theme => 'Thème';

  @override
  String get language => 'Langue';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get system => 'Système';

  @override
  String get english => 'Anglais';

  @override
  String get spanish => 'Espagnol';

  @override
  String get french => 'Français';
}
