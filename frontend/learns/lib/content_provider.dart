import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StudyMode { memorization, deep_understanding, contextual_association, interactive_evaluation }

class Flashcard {
  final String term;
  final String definition;
  Flashcard({required this.term, required this.definition});
  factory Flashcard.fromMap(Map<String, dynamic> m) => Flashcard(
        term: (m['term'] ?? '').toString(),
        definition: (m['definition'] ?? '').toString(),
      );
}

class QuizItem {
  final String question;
  final List<String> options;
  final int answerIndex;
  QuizItem({required this.question, required this.options, required this.answerIndex});
  factory QuizItem.fromMap(Map<String, dynamic> m) {
    final opts = (m['options'] as List? ?? []).map((e) => e.toString()).toList();
    final ans = (m['answer'] ?? m['answer_index'] ?? 0) as int;
    return QuizItem(question: (m['question'] ?? '').toString(), options: opts, answerIndex: ans);
  }
}

/// Single source of truth for analysis results & progress.
class ContentProvider extends ChangeNotifier {
  // --- Source inputs ---
  String? _content; // cleaned text
  String? _rawText; // raw transcript text

  // --- Content ---
  String? _summary;
  List<Flashcard> _flashcards = [];
  List<String> _conceptTopics = [];
  List<String> _deepPrompts = [];
  List<QuizItem> _quizzes = [];

  // --- Progress (lightweight) ---
  int _flashIndex = 0;
  bool _deepDone = false;
  int _quizScore = 0;
  String _contentHash = '';

  // --- Public getters ---
  String? get content => _content;
  String? get rawText => _rawText;
  String? get summary => _summary;
  List<Flashcard> get flashcards => _flashcards;
  List<String> get conceptTopics => _conceptTopics;
  List<String> get deepPrompts => _deepPrompts;
  List<QuizItem> get quizzes => _quizzes;

  int get flashIndex => _flashIndex;
  bool get deepDone => _deepDone;
  int get quizScore => _quizScore;
  String get contentHash => _contentHash;

  bool get hasAnyContent =>
      (_summary?.isNotEmpty ?? false) ||
      _flashcards.isNotEmpty ||
      _conceptTopics.isNotEmpty ||
      _deepPrompts.isNotEmpty ||
      _quizzes.isNotEmpty;

  set content(String? v) {
    _content = v;
    notifyListeners();
  }

  set rawText(String? v) {
    _rawText = v;
    notifyListeners();
  }

  // --- Helpers ---
  static String _hash(String s) {
    final bytes = utf8.encode(s);
    final sum = bytes.fold<int>(0, (a, b) => (a + b) & 0x7fffffff);
    return sum.toRadixString(36);
  }

  Future<void> _saveProgress() async {
    if (_contentHash.isEmpty) return;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('$_contentHash/flashIndex', _flashIndex);
    await sp.setBool('$_contentHash/deepDone', _deepDone);
    await sp.setInt('$_contentHash/quizScore', _quizScore);
  }

  Future<void> _loadProgress() async {
    if (_contentHash.isEmpty) return;
    final sp = await SharedPreferences.getInstance();
    _flashIndex = sp.getInt('$_contentHash/flashIndex') ?? 0;
    _deepDone = sp.getBool('$_contentHash/deepDone') ?? false;
    _quizScore = sp.getInt('$_contentHash/quizScore') ?? 0;
  }

  // Normalize various backend shapes to our typed structures.
  void setAnalysis(Map<String, dynamic> data) async {
    _summary = (data['summary'] ?? '').toString().trim();

    final fc = (data['flashcards'] ?? data['cards'] ?? []) as List? ?? [];
    _flashcards = fc.map((e) => Flashcard.fromMap(Map<String, dynamic>.from(e as Map))).toList();

    final rawTopics = data['concept_map'] ?? data['topics'] ?? [];
    if (rawTopics is List) {
      _conceptTopics = rawTopics.map((e) => e.toString()).toList();
    } else if (rawTopics is Map) {
      _conceptTopics = rawTopics.values.map((e) => e.toString()).toList();
    } else {
      _conceptTopics = [];
    }

    final rawDeep = data['deep_prompts'] ?? data['deep'] ?? [];
    _deepPrompts = (rawDeep as List? ?? []).map((e) => e.toString()).toList();

    final rawQuiz = data['quizzes'] ?? data['quiz'] ?? data['questions'] ?? [];
    _quizzes = (rawQuiz as List? ?? [])
        .map((e) => QuizItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    final baseForHash = _summary?.isNotEmpty == true
        ? _summary!
        : _flashcards.map((f) => f.term).join('|');
    _contentHash = baseForHash.isNotEmpty ? _hash(baseForHash) : '';

    await _loadProgress();
    notifyListeners();
  }

  // --- Progress mutations ---
  void setFlashIndex(int idx) {
    _flashIndex = idx.clamp(0, _flashcards.isEmpty ? 0 : _flashcards.length - 1);
    _saveProgress();
    notifyListeners();
  }

  void markDeepDone() {
    _deepDone = true;
    _saveProgress();
    notifyListeners();
  }

  void saveQuizScore(int score) {
    _quizScore = score;
    _saveProgress();
    notifyListeners();
  }

  // Optional: clear when new upload/analysis starts
  void resetAll() {
    _summary = null;
    _flashcards = [];
    _conceptTopics = [];
    _deepPrompts = [];
    _quizzes = [];
    _flashIndex = 0;
    _deepDone = false;
    _quizScore = 0;
    _contentHash = '';
    notifyListeners();
  }
}
