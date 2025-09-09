// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get add => 'Agregar';

  @override
  String get progress => 'Progreso';

  @override
  String get library => 'Biblioteca';

  @override
  String get addContent => 'Agregar contenido';

  @override
  String get pasteText => 'Pegar texto';

  @override
  String get pasteTextDesc => 'Escribe o pega texto plano.';

  @override
  String get uploadPdf => 'Subir PDF';

  @override
  String get uploadPdfDesc => 'Elige un documento PDF para analizar.';

  @override
  String get uploadAudio => 'Subir audio';

  @override
  String get uploadAudioDesc => 'Elige un archivo de audio para transcripción.';

  @override
  String get uploadVideo => 'Subir video';

  @override
  String get uploadVideoDesc => 'Selecciona un video para transcripción.';

  @override
  String get analyzingTitle => 'Analizando';

  @override
  String get analyzingDots => 'Analizando…';

  @override
  String get analyzeFailed => 'El análisis falló. Inténtalo de nuevo.';

  @override
  String get uploadDocument => 'Subir documento';

  @override
  String get selectPdf => 'Seleccionar PDF';

  @override
  String get chooseAudio => 'Elegir audio';

  @override
  String get chooseVideo => 'Elegir video';

  @override
  String get fileTooLarge => 'Archivo supera 100 MB';

  @override
  String get maxUploadSize => 'Tamaño máximo: 100 MB';

  @override
  String get studyPack => 'Paquete de estudio';

  @override
  String get summary => 'Resumen';

  @override
  String get memorizationFlashcards => 'Memorización (tarjetas)';

  @override
  String get deepUnderstanding => 'Comprensión profunda';

  @override
  String get contextualAssociation => 'Asociación contextual';

  @override
  String get interactiveEvaluation => 'Evaluación interactiva (quiz)';

  @override
  String get clozeDrills => 'Ejercicios de huecos (rellenar)';

  @override
  String get save => 'Guardar';

  @override
  String get savedToLibrary => 'Guardado en la biblioteca';

  @override
  String get progressTrackingNotImplemented => 'Seguimiento de progreso no implementado';

  @override
  String get importJson => 'Importar JSON';

  @override
  String get noContentYet => 'Sin contenido aún';

  @override
  String exportedTo(Object path) {
    return 'Exportado a $path';
  }

  @override
  String get deletePackQuestion => '¿Eliminar paquete?';

  @override
  String get deletePackWarning => 'Esta acción no se puede deshacer.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get export => 'Exportar';

  @override
  String get rename => 'Renombrar';

  @override
  String get renameCourse => 'Renombrar curso';

  @override
  String get nameCannotBeEmpty => 'El nombre no puede estar vacío';

  @override
  String get addTextTitle => 'Agregar texto';

  @override
  String get enterTextHint => 'Ingresa o pega texto aquí';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get noDeepPrompts => 'No hay indicaciones profundas disponibles.';

  @override
  String get back => 'Regresar';

  @override
  String get hideHint => 'Ocultar pista';

  @override
  String get showHint => 'Mostrar pista';

  @override
  String get prev => 'Anterior';

  @override
  String get next => 'Siguiente';

  @override
  String get finish => 'Finalizar';

  @override
  String get flashcardsTitle => 'Tarjetas';

  @override
  String get noFlashcards => 'No hay tarjetas disponibles';

  @override
  String get term => 'Término';

  @override
  String get definition => 'Definición';

  @override
  String get conceptMapTitle => 'Mapa conceptual';

  @override
  String get noConceptMap => 'No hay mapa conceptual disponible';

  @override
  String get topics => 'Temas';

  @override
  String get clozeDrillsTitle => 'Ejercicios de huecos';

  @override
  String get showExplanation => 'Mostrar explicación';

  @override
  String get answer => 'Respuesta';

  @override
  String get results => 'Resultados';

  @override
  String score(Object score, Object total) {
    return 'Puntuación: $score / $total';
  }

  @override
  String get close => 'Cerrar';

  @override
  String get quizTitle => 'Quiz';

  @override
  String questionOf(Object current, Object total) {
    return 'Pregunta $current de $total';
  }

  @override
  String get overallProgress => 'Progreso general';

  @override
  String get methodProgress => 'Progreso del método';

  @override
  String get studyTime => 'Tiempo de estudio';

  @override
  String get sessions => 'Sesiones';

  @override
  String get packs => 'Paquetes';

  @override
  String get memorization => 'Memorización';

  @override
  String get conceptMap => 'Mapa conceptual';

  @override
  String get quiz => 'Quiz';

  @override
  String get recentStudyPacks => 'Paquetes de estudio recientes';

  @override
  String get startStudyingMessage => 'Comienza a estudiar para ver tu progreso';

  @override
  String transcriptionFailed(Object error) {
    return 'La transcripción falló: $error';
  }

  @override
  String get analysisFailed => 'Análisis falló';

  @override
  String get selectAudio => 'Seleccionar audio';

  @override
  String get transcribingDots => 'Transcribiendo…';

  @override
  String get transcribe => 'Transcribir';

  @override
  String get unableToAnalyze => 'No se puede analizar';

  @override
  String get settings => 'Configuración';

  @override
  String get theme => 'Tema';

  @override
  String get language => 'Idioma';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get system => 'Sistema';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get french => 'Francés';
}
