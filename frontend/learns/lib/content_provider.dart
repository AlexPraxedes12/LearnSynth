import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum StudyMode {
  memorization,
  deep_understanding,
  contextual_association,
  interactive_evaluation,
}

class Flashcard {
  final String term;
  final String definition;
  Flashcard({required this.term, required this.definition});
  factory Flashcard.fromMap(Map<String, dynamic> m) =>
      Flashcard(
        term: (m['term'] ?? '').toString(),
        definition: (m['definition'] ?? '').toString(),
      );
}

class QuizQ {
  final String question;
  final List<String> options;
  /// 0-based index
  final int answer;
  QuizQ({required this.question, required this.options, required this.answer});
  factory QuizQ.fromMap(Map<String, dynamic> m) {
    final opts =
        (m['options'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final ans = (m['answer'] is int)
        ? m['answer'] as int
        : int.tryParse('${m['answer'] ?? -1}') ?? -1;
    return QuizQ(
      question: (m['question'] ?? '').toString(),
      options: opts,
      answer: ans,
    );
  }
}

class ContentProvider extends ChangeNotifier {
  // Source inputs
  String? _content; // cleaned text (final text used downstream)
  String? _rawText; // raw transcript text before processing (optional)

  // Normalized analysis
  String _summary = '';
  List<Flashcard> _flashcards = [];
  List<QuizQ> _quiz = [];
  List<String> _conceptMap = [];
  List<String> _deepPrompts = [];

  // Public inputs
  String? get content => _content;
  String? get rawText => _rawText;
  set rawText(String? v) {
    _rawText = v;
    notifyListeners();
  }

  set content(String? v) {
    _content = v;
    notifyListeners();
  }

  // Normalized outputs
  String get summary => _summary;
  List<Flashcard> get flashcards => List.unmodifiable(_flashcards);
  List<QuizQ> get quiz => List.unmodifiable(_quiz);
  List<String> get conceptMap => List.unmodifiable(_conceptMap);
  List<String> get deepPrompts => List.unmodifiable(_deepPrompts);

  // Convenience flags
  bool get hasSummary => _summary.trim().isNotEmpty;
  bool get hasFlashcards => _flashcards.isNotEmpty;
  bool get hasQuiz =>
      _quiz.isNotEmpty && _quiz.every((q) => q.options.isNotEmpty && q.answer >= 0);
  bool get hasConceptMap => _conceptMap.isNotEmpty;
  bool get hasDeepPrompts => _deepPrompts.isNotEmpty;

  /// Normalize any backend shape into our typed structure.
  /// Expects keys like: summary, flashcards, quiz, concept_map, deep_prompts (fallbacks handled).
  void setAnalysis(Map<String, dynamic> data) {
    final summary = data['summary'] ?? data['Summary'] ?? '';
    _summary = summary.toString();

    final fcs = (data['flashcards'] ?? data['Flashcards'] ?? []) as List?;
    _flashcards = (fcs ?? const [])
        .whereType<Map>()
        .map((m) => Flashcard.fromMap(m.cast<String, dynamic>()))
        .toList();

    final qz = (data['quiz'] ?? data['Quiz'] ?? []) as List?;
    _quiz = (qz ?? const [])
        .whereType<Map>()
        .map((m) => QuizQ.fromMap(m.cast<String, dynamic>()))
        .toList();

    final cmap =
        (data['concept_map'] ?? data['topics'] ?? data['concepts'] ?? []) as List?;
    _conceptMap = (cmap ?? const []).map((e) => e.toString()).toList();

    final deep = (data['deep_prompts'] ?? data['questions'] ?? []) as List?;
    _deepPrompts = (deep ?? const []).map((e) => e.toString()).toList();

    notifyListeners();
  }
}

