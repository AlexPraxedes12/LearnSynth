// Utility to generate human-friendly course names based on StudyPack content.

String generateCourseName(Map<String, dynamic> pack) {
  final flashcards = (pack['flashcards'] as List?) ?? const [];
  final conceptMaps = (pack['conceptGroups'] as List?) ?? const [];
  final quizzes = (pack['quiz'] as List?) ?? const [];

  String? topic;

  if (flashcards.isNotEmpty) {
    final term = (flashcards.first['term'] ?? '').toString().trim();
    if (term.isNotEmpty) topic = term;
  } else if (conceptMaps.isNotEmpty) {
    final firstGroup = conceptMaps.first as Map?;
    if (firstGroup != null) {
      var title = (firstGroup['title'] ?? '').toString().trim();
      final topics = (firstGroup['topics'] as List?) ?? const [];
      if (title.isEmpty && topics.isNotEmpty) {
        title = topics.first.toString();
      }
      if (title == 'Topics' && topics.isNotEmpty) {
        title = topics.first.toString();
      }
      if (title.isNotEmpty) topic = title;
    }
  } else if (quizzes.isNotEmpty) {
    final question = (quizzes.first['question'] ?? '').toString().trim();
    if (question.isNotEmpty) topic = question;
  }

  final hasFlashcards = flashcards.isNotEmpty;
  final hasConcepts = conceptMaps.isNotEmpty;
  final hasQuiz = quizzes.isNotEmpty;
  final types = [hasFlashcards, hasConcepts, hasQuiz].where((e) => e).length;

  String name;
  if (types > 1 && topic != null) {
    name = '$topic - Curso completo';
  } else if (hasFlashcards && topic != null) {
    name = 'Flashcards: $topic';
  } else if (hasConcepts && topic != null) {
    name = 'Conceptos: $topic';
  } else if (hasQuiz && topic != null) {
    name = 'Quiz: $topic';
  } else {
    final createdAt = (pack['createdAt'] ?? '').toString();
    final id = (pack['id'] ?? '').toString();
    final dt = DateTime.tryParse(createdAt);
    if (dt != null) {
      name = 'Curso ${dt.month}/${dt.day}/${dt.year}';
    } else if (id.isNotEmpty) {
      name = 'Study Pack $id';
    } else {
      name = 'Study Pack';
    }
  }

  if (name.length > 25) {
    name = name.substring(0, 25);
  }
  return name;
}

/// Returns a user-visible name for a study pack using, in order of
/// precedence, any custom name, the explicit title field, or a generated
/// fallback based on the pack contents.
String getDisplayName(Map<String, dynamic> pack) {
  final custom = pack['customName']?.toString().trim();
  if (custom != null && custom.isNotEmpty) {
    return custom;
  }

  final title = pack['title']?.toString().trim();
  if (title != null && title.isNotEmpty) {
    return title;
  }

  return generateCourseName(pack);
}

