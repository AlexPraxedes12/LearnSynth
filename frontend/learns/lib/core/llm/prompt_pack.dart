class PromptPack {
  static String analyze(String text) => '''Analiza el siguiente texto y responde en JSON con las llaves "transcript", "summary", "tags" (lista) y "deep_prompts" (lista).\n\n$text''';

  static String flashcards(String text) => '''Genera una lista JSON de objetos con llaves "term" y "definition" a partir de este texto:\n\n$text''';

  static String conceptGraph(String text) => '''Construye en JSON un grafo de conceptos con llaves "groups", "nodes" y "relations" usando este texto:\n\n$text''';

  static String quiz(String text) => '''Genera preguntas tipo test en JSON con llaves "question", "options" y "answerIndex" basadas en este texto:\n\n$text''';

  static String cloze(String text) => '''Genera oraciones con huecos en JSON con llaves "sentence", "options" y "answerIndex" basadas en este texto:\n\n$text''';
}
