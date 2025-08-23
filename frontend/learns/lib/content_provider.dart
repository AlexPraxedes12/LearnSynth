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

  bool isAnalyzing = false;
  bool canContinue = false;
  String? lastError;

  Future<bool>? _inflight;

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
  String? get summary => _summary?.isNotEmpty == true ? _summary : null;
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

  void setTranscript(String text) {
    _rawText = text.trim();
    lastError = null;
    canContinue = false;
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

  Future<bool> runAnalysis() {
    _inflight ??=
        _runAnalysisInternal().whenComplete(() => _inflight = null);
    return _inflight!;
  }

  Future<bool> _runAnalysisInternal() async {
    if (isAnalyzing) return false; // extra guard

    print(
        '[ContentProvider] runAnalysis start (has raw: ${_rawText?.isNotEmpty == true}, has content: ${_content?.isNotEmpty == true})');

    final text = (_rawText?.trim().isNotEmpty == true)
        ? _rawText!.trim()
        : (_content?.trim().isNotEmpty == true ? _content!.trim() : '');

    if (text.isEmpty) {
      lastError = 'Nothing to analyze.';
      notifyListeners();
      print(
          '[ContentProvider] runAnalysis done -> canContinue=$canContinue, err=$lastError');
      return false;
    }

    isAnalyzing = true;
    lastError = null;
    notifyListeners();

    try {
      final url = Uri.parse('http://10.0.2.2:8000/analyze');
      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 60));

      if (resp.statusCode != 200) {
        lastError = 'Analyze failed: ${resp.statusCode}';
        canContinue = false;
        notifyListeners();
        return false;
      }

      final Map<String, dynamic> data = jsonDecode(resp.body);

      String _toStr(dynamic v) => (v ?? '').toString().trim();
      List<String> _toStrList(dynamic v) =>
          (v as List? ?? const [])
              .map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList();

      _summary = _toStr(data['summary']);
      _flashcards =
          _coerceFlashcards(data['flashcards'] ?? data['cards']);
      _conceptTopics =
          _toStrList(data['topics'] ?? data['concepts']);
      _deepPrompts =
          _toStrList(data['deep_prompts'] ?? data['deep']);
      _quizzes = _coerceQuiz(data['quiz'] ?? data['quizzes']);

      final baseForHash = _summary?.isNotEmpty == true
          ? _summary!
          : _flashcards.map((f) => f.term).join('|');
      _contentHash = baseForHash.isNotEmpty ? _hash(baseForHash) : '';

      await _saveProgress();

      canContinue = true;
      lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      lastError = 'Analyze error: $e';
      canContinue = false;
      notifyListeners();
      return false;
    } finally {
      isAnalyzing = false;
      notifyListeners();
      print(
          '[ContentProvider] runAnalysis done -> canContinue=$canContinue, err=$lastError');
    }
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
    canContinue = false;
    lastError = null;
    notifyListeners();
  }
}
