import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'services/transcription_service.dart';

/// ----- New typed models -----
class DeepPrompt {
  final String prompt;
  final String hint;
  DeepPrompt({required this.prompt, this.hint = ''});

  factory DeepPrompt.fromMap(Map<String, dynamic> m) {
    final p =
        (m['prompt'] ?? m['text'] ?? m['question'] ?? '').toString().trim();
    final h = (m['hint'] ?? m['explanation'] ?? '').toString().trim();
    return DeepPrompt(prompt: p, hint: h);
  }
}

class ConceptGroup {
  final String title;
  final List<String>? topics;
  ConceptGroup({required this.title, required this.topics});

  factory ConceptGroup.fromMap(Map<String, dynamic> m) {
    final title = (m['title'] ?? m['group'] ?? 'Topics').toString().trim();
    final raw = (m['topics'] as List?) ?? const [];
    final topics = raw.map((e) => e.toString()).toList();
    return ConceptGroup(title: title, topics: topics);
  }
}

class ConceptMapData {
  final List<ConceptGroup> groups;
  final List<String> nodes;
  final List<Map<String, String>> relations;
  ConceptMapData({required this.groups, required this.nodes, required this.relations});
}

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
  File? _selectedAudio;
  File? _selectedVideo;
  bool _isAnalyzing = false;
  bool _canContinue = false;
  String? _lastError;

  File? get selectedAudio => _selectedAudio;
  File? get selectedVideo => _selectedVideo;
  bool get isAnalyzing => _isAnalyzing;
  bool get canContinue => _canContinue;
  String? get lastError => _lastError;

  // --- Content ---
  String? _summary;
  final List<Flashcard> _flashcards = [];
  final List<QuizItem> _quizzes = [];
  List<DeepPrompt>? _deepPrompts;
  List<ConceptGroup>? _conceptGroups;
  List<String> _conceptTopics = [];
  List<String> _conceptNodes = [];
  List<Map<String, String>> _conceptRelations = [];

  // --- Progress (lightweight) ---
  int _flashIndex = 0;
  int _deepIndex = 0;
  bool _deepDone = false;
  int _quizScore = 0;
  String _contentHash = '';

  // --- Public getters ---
  String? get content => _content;
  String? get rawText => _rawText;
  String? get summary => _summary?.isNotEmpty == true ? _summary : null;
  List<Flashcard> get flashcards => _flashcards;
  List<DeepPrompt> get deepPrompts => _deepPrompts ?? [];
  List<ConceptGroup> get conceptGroups => _conceptGroups ?? [];
  List<String> get conceptTopics => _conceptTopics;
  List<String> get conceptNodes => _conceptNodes;
  List<Map<String, String>> get conceptRelations => _conceptRelations;

  bool get canDeep => _listNotEmpty(_deepPrompts);
  bool get hasDeep => canDeep; // backward compatibility
  bool get canConcept =>
      _listNotEmpty(_conceptGroups) || _conceptTopics.isNotEmpty;

  List<QuizItem> get quizzes => _quizzes;

  int get flashIndex => _flashIndex;
  int get deepIndex => _deepIndex;
  bool get deepDone => _deepDone;
  int get quizScore => _quizScore;
  String get contentHash => _contentHash;

  bool get hasTranscript => (_rawText ?? '').trim().isNotEmpty;

  bool get hasAnalysis =>
      (summary?.isNotEmpty ?? false) ||
      _flashcards.isNotEmpty ||
      _listNotEmpty(_deepPrompts) ||
      _listNotEmpty(_conceptGroups) ||
      _conceptTopics.isNotEmpty ||
      _quizzes.isNotEmpty;

  // Convenience flags for content availability
  bool get hasMemorization => _flashcards.isNotEmpty;
  bool get hasQuiz => _quizzes.isNotEmpty;

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
    _lastError = null;
    notifyListeners();
  }

  // --- Helpers ---
  static String _hash(String s) {
    final bytes = utf8.encode(s);
    final sum = bytes.fold<int>(0, (a, b) => (a + b) & 0x7fffffff);
    return sum.toRadixString(36);
  }

  bool _notEmpty(String? s) => s != null && s.trim().isNotEmpty;
  bool _listNotEmpty<T>(List<T>? l) => l != null && l.isNotEmpty;

  Future<void> _saveProgress() async {
    if (_contentHash.isEmpty) return;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('$_contentHash/flashIndex', _flashIndex);
    await sp.setInt('$_contentHash/deepIndex', _deepIndex);
    await sp.setBool('$_contentHash/deepDone', _deepDone);
    await sp.setInt('$_contentHash/quizScore', _quizScore);
  }

  Future<void> _loadProgress() async {
    if (_contentHash.isEmpty) return;
    final sp = await SharedPreferences.getInstance();
    _flashIndex = sp.getInt('$_contentHash/flashIndex') ?? 0;
    _deepIndex = sp.getInt('$_contentHash/deepIndex') ?? 0;
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

  ConceptMapData _parseConceptMap(dynamic cm) {
    final groups = <ConceptGroup>[];
    final nodes = <String>[];
    final relations = <Map<String, String>>[];

    if (cm is Map && cm['groups'] is List) {
      for (final g in cm['groups'] as List) {
        final m = (g as Map?) ?? const {};
        final title = (m['title'] ?? m['group'] ?? 'Topics').toString();
        final topics = ((m['topics'] as List?) ?? const [])
            .map((t) => t.toString())
            .where((t) => t.trim().isNotEmpty)
            .toList();
        if (topics.isEmpty) continue;
        groups.add(ConceptGroup(title: title, topics: topics));
        nodes.add(title);
        for (final t in topics) {
          nodes.add(t);
          relations.add({'from': title, 'to': t});
        }
      }
    } else if (cm is List) {
      final topics = cm
          .map((t) => t.toString())
          .where((t) => t.trim().isNotEmpty)
          .toList();
      if (topics.isNotEmpty) {
        groups.add(ConceptGroup(title: 'Topics', topics: topics));
        nodes.add('Topics');
        for (final t in topics) {
          nodes.add(t);
          relations.add({'from': 'Topics', 'to': t});
        }
      }
    }

    return ConceptMapData(groups: groups, nodes: nodes, relations: relations);
  }

  // --- Selection helpers ---
  void setSelectedAudio(File f) {
    _selectedAudio = f;
    _selectedVideo = null;
    _rawText = null;
    _content = null;
    _lastError = null;
    _canContinue = false;
    notifyListeners();
  }

  void setSelectedVideo(File f) {
    _selectedVideo = f;
    _selectedAudio = null;
    _rawText = null;
    _content = null;
    _lastError = null;
    _canContinue = false;
    notifyListeners();
  }

  Future<bool>? _inflightAnalysis;

  Future<bool> runAnalysis() {
    _inflightAnalysis ??= _runAnalysisInternal();
    return _inflightAnalysis!;
  }

  Future<bool> _runAnalysisInternal() async {
    if (_isAnalyzing) return _canContinue;

    _isAnalyzing = true;
    _lastError = null;
    notifyListeners();

    try {
      // Ensure we have text to analyze, transcribing if necessary.
      String text = (_rawText?.trim().isNotEmpty == true ? _rawText! : _content ?? '').trim();
      if (text.isEmpty && _selectedAudio != null) {
        text = (await TranscriptionService().sendFile(_selectedAudio!)) ?? '';
        _rawText = text;
        _content = text;
      } else if (text.isEmpty && _selectedVideo != null) {
        text = (await TranscriptionService().sendFile(_selectedVideo!)) ?? '';
        _rawText = text;
        _content = text;
      }

      text = text.trim();
      if (text.isEmpty) {
        _lastError = 'Nothing to analyze.';
        return false;
      }

      final uri = Uri.parse('http://10.0.2.2:8000/analyze');
      final resp = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'text': text}))
          .timeout(const Duration(seconds: 60));

      if (resp.statusCode >= 500) {
        throw Exception('Server error ${resp.statusCode}');
      }
      if (resp.statusCode >= 400) {
        _lastError = 'Analyze failed: ${resp.statusCode}';
        return false;
      }

      final Map<String, dynamic> data = jsonDecode(resp.body);

      // Summary
      _summary = (data['summary'] ?? '').toString().trim();

      // Flashcards & quiz (tolerant)
      _flashcards
        ..clear()
        ..addAll(_coerceFlashcards(data['flashcards'] ?? data['cards']));
      _quizzes
        ..clear()
        ..addAll(_coerceQuiz(data['quiz'] ?? data['quizzes']));

      // Deep prompts
      final dp = data['deep_prompts'];
      _deepPrompts = (dp is List)
          ? dp
              .map((e) {
                final m = (e as Map?) ?? const {};
                return DeepPrompt(
                  prompt:
                      (m['prompt'] ?? m['question'] ?? m['text'] ?? '').toString(),
                  hint: (m['hint'] ?? m['explanation'] ?? '').toString(),
                );
              })
              .where((p) => p.prompt.trim().isNotEmpty)
              .toList()
          : <DeepPrompt>[];

      // Concept map
      final cmap = _parseConceptMap(data['concept_map']);
      _conceptGroups = cmap.groups;
      _conceptNodes = cmap.nodes;
      _conceptRelations = cmap.relations;

      // --- Concept map (null-safe) ---
      final groups = _conceptGroups ?? [];
      _conceptTopics = (groups.length == 1 && groups.first.title == 'Topics')
          ? (groups.first.topics ?? [])
          : [];

      // Enable CTAs only if there is something to show
      _canContinue =
          _notEmpty(_summary) || _listNotEmpty(_deepPrompts) || groups.isNotEmpty;

      // --- Hash base (null-safe) ---
      final baseForHash = _notEmpty(_summary)
          ? _summary!.trim()
          : _flashcards.map((f) => f.term).join('|');

      _contentHash = baseForHash.isNotEmpty ? _hash(baseForHash) : '';
      await _loadProgress();
      await _saveProgress();
      return _canContinue;
    } catch (e) {
      _lastError = e.toString();
      return false;
    } finally {
      _isAnalyzing = false;
      _inflightAnalysis = null;
      notifyListeners();
    }
  }
  
  // Legacy helpers used by older flows.
  Future<void> transcribeAndAnalyze(File file) async {
    setSelectedAudio(file);
    await runAnalysis();
  }

  void resetTranscribeFlow() {
    resetAll();
  }

  // --- Progress mutations ---
  void setFlashIndex(int idx) {
    _flashIndex = idx.clamp(0, _flashcards.isEmpty ? 0 : _flashcards.length - 1);
    _saveProgress();
    notifyListeners();
  }

  void setDeepIndex(int idx) {
    final max = _listNotEmpty(_deepPrompts) ? _deepPrompts!.length - 1 : 0;
    _deepIndex = idx.clamp(0, max);
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

  // HARD RESET: called when returning to home
  void resetAll({bool notify = true}) {
    _selectedAudio = null;
    _selectedVideo = null;
    _rawText = null;
    _content = null;
    _lastError = null;
    _isAnalyzing = false;
    _canContinue = false;
    _summary = null;
    _flashcards.clear();
    _deepPrompts = null;
    _conceptGroups = null;
    _conceptTopics = [];
    _conceptNodes = [];
    _conceptRelations = [];
    _quizzes.clear();
    _flashIndex = 0;
    _deepIndex = 0;
    _deepDone = false;
    _quizScore = 0;
    _contentHash = '';

    if (notify) {
      // Defer notification until the next frame to avoid calling listeners
      // while the widget tree is locked during dispose.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
}
