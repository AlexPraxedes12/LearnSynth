import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
    final raw = m['answer'] ?? m['answer_index'] ?? 0;
    final ans = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
    return QuizItem(
        question: (m['question'] ?? '').toString(),
        options: opts,
        answerIndex: ans);
  }
}

/// Single source of truth for analysis results & progress.
class ContentProvider extends ChangeNotifier {
  // --- Source inputs ---
  String? _content; // cleaned text
  String? _rawText; // raw transcript text

  bool _isAnalyzing = false;
  Future<void>? _inflightAnalysis;

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

  bool get isAnalyzing => _isAnalyzing;
  bool get canContinue => _summary?.isNotEmpty == true;

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

  void setTranscript(String text) {
    _rawText = text;
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
  Future<void> setAnalysis(Map<String, dynamic> data) async {
    try {
      _summary = (data['summary'] ?? '').toString().trim();
      _flashcards = _coerceFlashcards(data['flashcards'] ?? data['cards']);
      _quizzes = _coerceQuiz(data['quizzes'] ?? data['quiz'] ?? data['questions']);
      _conceptTopics = _coerceTopics(
          data['concept_map'] ?? data['conceptMap'] ?? data['topics']);
      _deepPrompts =
          (data['deep_prompts'] ?? data['deep'] ?? [])
              .map((e) => e.toString())
              .toList();

      final baseForHash = _summary?.isNotEmpty == true
          ? _summary!
          : _flashcards.map((f) => f.term).join('|');
      _contentHash = baseForHash.isNotEmpty ? _hash(baseForHash) : '';

      await _saveProgress();
      notifyListeners();
    } catch (e, st) {
      rethrow;
    }
  }

  List<Flashcard> _coerceFlashcards(dynamic raw) {
    final list = (raw as List? ?? []);
    return list
        .map((e) => Flashcard.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<QuizItem> _coerceQuiz(dynamic raw) {
    final list = (raw as List? ?? []);
    return list
        .map((e) => QuizItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<String> _coerceTopics(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    } else if (raw is Map) {
      return raw.values.map((e) => e.toString()).toList();
    }
    return [];
  }

  Future<void> runAnalysis() {
    if (_inflightAnalysis != null) return _inflightAnalysis!;

    final completer = Completer<void>();
    _isAnalyzing = true;
    notifyListeners();

    _inflightAnalysis = _doRunAnalysis().then((_) {
      completer.complete();
    }).catchError((e, st) {
      completer.completeError(e, st);
    }).whenComplete(() {
      _isAnalyzing = false;
      _inflightAnalysis = null;
      notifyListeners();
    });

    return completer.future;
  }

  Future<void> _doRunAnalysis() async {
    if ((_rawText ?? '').trim().isEmpty) {
      throw StateError('No transcript to analyze');
    }
    final url = Uri.parse('http://10.0.2.2:8000/analyze');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'text': _rawText}),
    );
    if (resp.statusCode != 200) {
      throw StateError('Analyze failed: ${resp.statusCode}');
    }
    final map = json.decode(resp.body) as Map<String, dynamic>;
    await setAnalysis(map);
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
