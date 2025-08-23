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
  final String? hint;
  DeepPrompt({required this.prompt, this.hint});
  factory DeepPrompt.fromMap(Map<String, dynamic> m) => DeepPrompt(
        prompt: (m['prompt'] ?? m['text'] ?? m['question'] ?? '')
            .toString()
            .trim(),
        hint: (m['hint'] ?? m['explanation'])?.toString().trim(),
      );
}

class ConceptGroup {
  final String title;
  final List<String> topics;
  ConceptGroup({required this.title, required this.topics});
  factory ConceptGroup.fromMap(Map<String, dynamic> m) => ConceptGroup(
        title: (m['title'] ?? m['name'] ?? 'Topics').toString(),
        topics: List<String>.from(
            (m['topics'] ?? m['items'] ?? const []).map((e) => e.toString())),
      );
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

  Future<bool>? _inflight;

  // --- Content ---
  String? _summary;
  final List<Flashcard> _flashcards = [];
  final List<String> _conceptTopics = [];
  final List<QuizItem> _quizzes = [];
  // New: deep prompts + grouped concept map
  List<DeepPrompt> _deepPrompts = [];
  List<ConceptGroup> _conceptGroups = [];

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
  List<DeepPrompt> get deepPrompts => List.unmodifiable(_deepPrompts);
  List<ConceptGroup> get conceptGroups => List.unmodifiable(_conceptGroups);
  List<String> get conceptTopics => _conceptGroups.isEmpty
      ? List<String>.from(_conceptTopics)
      : _conceptGroups.expand((g) => g.topics).toSet().toList();
  bool get hasConceptGroups => _conceptGroups.isNotEmpty;

  // Availability flags used by CTAs
  bool get hasDeep => _deepPrompts.isNotEmpty;
  bool get canDeep => hasDeep; // deprecated alias
  bool get canConcept =>
      _conceptGroups.isNotEmpty || _conceptTopics.isNotEmpty; // drives CTA

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
      _deepPrompts.isNotEmpty ||
      _conceptGroups.isNotEmpty ||
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

  void setAnalysis(Map<String, dynamic> data) {
    String _toStr(dynamic v) => (v ?? '').toString().trim();

    _summary = _toStr(data['summary'] ?? data['synopsis']);
    _flashcards
      ..clear()
      ..addAll(_coerceFlashcards(data['flashcards'] ?? data['cards']));
    _quizzes
      ..clear()
      ..addAll(_coerceQuiz(data['quiz'] ?? data['quizzes']));

    // ---- Concept Map (grouped OR flat) normalization ----
    _conceptGroups.clear();
    _conceptTopics.clear();
    final cmap = data['concept_map'];
    if (cmap is Map && cmap['groups'] is List) {
      _conceptGroups = (cmap['groups'] as List)
          .whereType<Map>()
          .map((m) => ConceptGroup.fromMap(Map<String, dynamic>.from(m)))
          .where((g) => g.topics.isNotEmpty)
          .toList();
    }
    if (_conceptGroups.isEmpty) {
      final rawTopics = data['concepts'];
      if (rawTopics is List) {
        _conceptTopics
            .addAll(rawTopics.map((e) => e.toString()));
      }
    }

    // ---- Deep Prompts normalization ----
    final rawDeep =
        (data['deep_prompts'] ?? data['deep']) as List? ?? const [];
    _deepPrompts = rawDeep
        .map((e) => DeepPrompt.fromMap(e as Map<String, dynamic>))
        .where((p) => p.prompt.isNotEmpty)
        .toList();

    if (kDebugMode) {
      debugPrint('[ContentProvider] keys: ${data.keys.toList()}');
      debugPrint('[ContentProvider] deepPrompts: ${_deepPrompts.length} | groups: ${_conceptGroups.length} | topics: ${_conceptTopics.length}');
    }

    notifyListeners();
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

  // Single-flight runner used by the Analyzing screen.
  Future<void> ensureAnalysisStarted() async {
    if (_isAnalyzing || _canContinue) return;

    _isAnalyzing = true;
    _lastError = null;
    notifyListeners();

    try {
      if (_selectedAudio != null) {
        final txt = await TranscriptionService().sendFile(_selectedAudio!);
        _rawText = txt ?? '';
      } else if (_selectedVideo != null) {
        final txt = await TranscriptionService().sendFile(_selectedVideo!);
        _rawText = txt ?? '';
      } else if ((_rawText ?? '').isNotEmpty) {
        // text already provided
      } else {
        throw StateError('No file selected');
      }

      final ok = await runAnalysis();
      _canContinue = ok == true;
    } catch (e) {
      _lastError = e.toString();
      _canContinue = false;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<bool> runAnalysis({String? textOverride}) {
    _inflight ??=
        _runAnalysisInternal(textOverride: textOverride).whenComplete(() {
      _inflight = null;
    });
    return _inflight!;
  }

  Future<bool> _runAnalysisInternal({String? textOverride}) async {
    _isAnalyzing = true;
    _lastError = null;
    _canContinue = false;
    notifyListeners();

    try {
      final text = (textOverride ?? _rawText ?? '').trim();
      if (text.isEmpty) {
        _lastError = 'Nothing to analyze.';
        return false;
      }

      final url = Uri.parse('http://10.0.2.2:8000/analyze');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (resp.statusCode != 200) {
        _lastError = 'Analyze failed: ${resp.statusCode}';
        return false;
      }

      final Map<String, dynamic> data = jsonDecode(resp.body);

      setAnalysis(data);

      final baseForHash =
          _summary?.isNotEmpty == true
              ? _summary!
              : _flashcards.map((f) => f.term).join('|');
      _contentHash = baseForHash.isNotEmpty ? _hash(baseForHash) : '';
      await _loadProgress();
      await fetchStudyMode(textOverride: text);
      await _saveProgress();
      _canContinue = true;
      return true;
    } catch (e) {
      _lastError = e.toString();
      _canContinue = false;
      return false;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchStudyMode({String? textOverride}) async {
    final text = (textOverride ?? _rawText ?? '').trim();
    if (text.isEmpty) return;

    try {
      final url = Uri.parse('http://10.0.2.2:8000/study-mode');
      final resp = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}));
      if (resp.statusCode != 200) return;
      final Map<String, dynamic> data = jsonDecode(resp.body);

      // Parse deep prompts
      final rawDeep =
          (data['deep_prompts'] ?? data['deep']) as List? ?? const [];
      _deepPrompts = rawDeep
          .map((e) => DeepPrompt.fromMap(e as Map<String, dynamic>))
          .where((p) => p.prompt.isNotEmpty)
          .toList();

      // Parse concept map if provided
      final cmap = data['concept_map'] ?? data['conceptMap'];
      _conceptGroups.clear();
      if (cmap is Map && cmap['groups'] is List) {
        _conceptGroups = (cmap['groups'] as List)
            .whereType<Map>()
            .map((m) => ConceptGroup.fromMap(Map<String, dynamic>.from(m)))
            .where((g) => g.topics.isNotEmpty)
            .toList();
      }

      // Clamp persisted index to available prompts
      _deepIndex = _deepIndex.clamp(
          0, _deepPrompts.isEmpty ? 0 : _deepPrompts.length - 1);

      notifyListeners();
    } catch (_) {
      // Ignore errors; deep prompts are optional
    }
  }
  // Legacy helpers used by older flows.
  Future<void> transcribeAndAnalyze(File file) async {
    setSelectedAudio(file);
    await ensureAnalysisStarted();
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
    _deepIndex =
        idx.clamp(0, _deepPrompts.isEmpty ? 0 : _deepPrompts.length - 1);
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
    _deepPrompts.clear();
    _conceptGroups.clear();
    _conceptTopics.clear();
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
