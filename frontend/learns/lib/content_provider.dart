import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'services/transcription_service.dart';
import 'core/llm/llm_router.dart';
import 'core/llm/offline_tasks.dart';
import 'core/llm/providers_local.dart';
import 'core/llm/providers_backend.dart';
import 'core/llm/providers_heuristic.dart';
import 'core/llm/analyze_result.dart';
import 'core/net/api_config.dart';
import 'core/net/json_sugar.dart' show mapifyResponse;
import 'core/net/backend_client.dart';
import 'core/sync/sync_queue.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'package:learnsynth/services/offline_llm_compat.dart';
import 'core/course_name_generator.dart';
import 'config/env.dart';

/// ----- New typed models -----
class RunInfo {
  final String providerId; // 'offline' | 'backend'
  final bool offlinePref;
  final bool hasNet;
  final DateTime startedAt;

  RunInfo(this.providerId, this.offlinePref, this.hasNet, this.startedAt);
  static RunInfo empty() =>
      RunInfo('', false, false, DateTime.fromMillisecondsSinceEpoch(0));
}

final currentRunInfo = ValueNotifier<RunInfo>(RunInfo.empty());

/// ----- New typed models -----
class DeepPrompt {
  final String prompt;
  final String hint;
  DeepPrompt({required this.prompt, this.hint = ''});

  factory DeepPrompt.fromMap(Map<String, dynamic> m) {
    final p = (m['prompt'] ?? m['text'] ?? m['question'] ?? '')
        .toString()
        .trim();
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
  ConceptMapData({
    required this.groups,
    required this.nodes,
    required this.relations,
  });
}

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
  factory Flashcard.fromMap(Map<String, dynamic> m) => Flashcard(
    term: (m['term'] ?? '').toString(),
    definition: (m['definition'] ?? '').toString(),
  );
}

class QuizItem {
  final String question;
  final List<String> options;
  final int answerIndex;
  QuizItem({
    required this.question,
    required this.options,
    required this.answerIndex,
  });
  factory QuizItem.fromMap(Map<String, dynamic> m) {
    final opts = (m['options'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final raw = m['answer'] ?? m['answer_index'] ?? 0;
    final ans = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
    return QuizItem(
      question: (m['question'] ?? '').toString(),
      options: opts,
      answerIndex: ans,
    );
  }
}

class ClozeItem {
  final String sentence;
  final List<String> options;
  final int answerIndex;
  ClozeItem({
    required this.sentence,
    required this.options,
    required this.answerIndex,
  });
  factory ClozeItem.fromMap(Map<String, dynamic> m) {
    final opts = (m['options'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final raw = m['answerIndex'] ?? m['answer'] ?? 0;
    final ans = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
    return ClozeItem(
      sentence: (m['sentence'] ?? '').toString(),
      options: opts,
      answerIndex: ans,
    );
  }
}

/// Single source of truth for analysis results & progress.
class ContentProvider extends ChangeNotifier {
  // --- Source inputs ---
  String? _content; // cleaned text
  String? _rawText; // raw transcript text
  ({Uint8List bytes, String name})? _selectedAudio;
  ({Uint8List bytes, String name})? _selectedVideo;
  bool _isAnalyzing = false;
  bool _canContinue = false;
  String? _lastError;

  HeuristicOfflineLLMProvider? _heu;
  LLMProvider? _pLocal; // plugin
  LLMProvider? _pBack; // Replicate/backend
  String _packId = const Uuid().v4();

  ({Uint8List bytes, String name})? get selectedAudio => _selectedAudio;
  ({Uint8List bytes, String name})? get selectedVideo => _selectedVideo;
  bool get isAnalyzing => _isAnalyzing;
  bool get canContinue => _canContinue;
  String? get lastError => _lastError;

  bool _justSaved = false;
  bool get justSaved => _justSaved;
  void clearJustSaved() => _justSaved = false;

  // --- Content ---
  String? _summary;
  List<String> _tags = [];
  final List<Flashcard> _flashcards = [];
  final List<QuizItem> _quizzes = [];
  final List<ClozeItem> _cloze = [];
  List<DeepPrompt>? _deepPrompts;
  List<String> _deepResponses = [];
  List<bool> _deepCompleted = [];
  List<ConceptGroup>? _conceptGroups;
  List<String> _conceptTopics = [];
  List<String> _conceptNodes = [];
  List<Map<String, String>> _conceptRelations = [];

  List<String> _textSegments = [];

  // --- Progress (lightweight) ---
  int _flashIndex = 0;
  int _deepIndex = 0;
  bool _deepDone = false;
  int _quizScore = 0;
  String _contentHash = '';

  // --- Method progress tracking ---
  final Map<String, double> _methodProgress = {};
  final Map<String, int> _methodTime = {};
  final Map<String, Map<String, double>> _allPacksProgress = {};
  final Map<String, int> _cumulativeMethodTime = {};
  DateTime? _sessionStart;
  int _totalStudyTime = 0;
  int _completedSessions = 0;
  final Map<String, double> _packProgress = {};
  final Map<String, int> _packStudyTime = {};
  Stopwatch? _courseTimer;
  String? _currentTimerPackId;
  SharedPreferences? _prefs;

  ContentProvider() {
    _initPrefs();
  }

  Future<void> _ensureProviders() async {
    _heu ??= HeuristicOfflineLLMProvider();
    if (Env.enableOfflineLLM) {
      _pLocal ??= LocalOfflineLLMProvider();
    }
    _pBack ??= BackendLLMProvider(ApiConfig.apiBase);
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _totalStudyTime = _prefs?.getInt('totalStudyTime') ?? 0;
    _completedSessions = _prefs?.getInt('completedSessions') ?? 0;
    for (final method in ['flash', 'deep', 'concept', 'quiz', 'cloze']) {
      _cumulativeMethodTime[method] =
          _prefs?.getInt('cumulative_$method') ?? 0;
    }

    for (final k in _prefs!.getKeys()) {
      if (k.startsWith('overall_progress_')) {
        final id = k.substring('overall_progress_'.length);
        _packProgress[id] = _prefs!.getDouble(k) ?? 0.0;
      } else if (k.startsWith('progress_')) {
        final parts = k.split('_');
        if (parts.length >= 3) {
          final packId = parts[1];
          final method = parts[2];
          _allPacksProgress[packId] ??= {};
          _allPacksProgress[packId]![method] =
              _prefs!.getDouble(k) ?? 0.0;
        }
      } else if (k.startsWith('study_time_')) {
        final id = k.substring('study_time_'.length);
        _packStudyTime[id] = _prefs!.getInt(k) ?? 0;
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // --- Public getters ---
  String? get content => _content;
  String? get rawText => _rawText;
  String? get summary => _summary?.isNotEmpty == true ? _summary : null;
  List<String> get tags => _tags;
  List<Flashcard> get flashcards => _flashcards;
  List<DeepPrompt> get deepPrompts => _deepPrompts ?? [];
  List<String> get deepResponses => _deepResponses;
  List<bool> get deepCompleted => _deepCompleted;
  List<String> get textSegments => _textSegments;
  List<ConceptGroup> get conceptGroups => _conceptGroups ?? [];
  List<String> get conceptTopics => _conceptTopics;
  List<String> get conceptNodes => _conceptNodes;
  List<Map<String, String>> get conceptRelations => _conceptRelations;

  String get packId => _packId;

  bool get canDeep =>
      (_summary?.trim().isNotEmpty ?? false) || (_rawText?.trim().isNotEmpty ?? false);
  bool get hasDeep => canDeep; // backward compatibility
  bool get canConcept =>
      _conceptNodes.isNotEmpty && _conceptRelations.isNotEmpty;

  List<QuizItem> get quizzes => _quizzes;
  List<ClozeItem> get cloze => _cloze;

  int get flashIndex => _flashIndex;
  int get deepIndex => _deepIndex;
  bool get deepDone => _deepDone;
  int get quizScore => _quizScore;
  String get contentHash => _contentHash;
  Map<String, double> get methodProgress => Map.unmodifiable(_methodProgress);
  int get totalStudyTime => _totalStudyTime;
  int get completedSessions => _completedSessions;
  double get overallProgress {
    if (_methodProgress.isEmpty) return 0;
    return _methodProgress.values.reduce((a, b) => a + b) / _methodProgress.length;
  }

  double get overallCumulativeProgress {
    if (_packProgress.isEmpty) return 0;
    return _packProgress.values.reduce((a, b) => a + b) / _packProgress.length;
  }

  double getCumulativeMethodProgress(String method) {
    if (_allPacksProgress.isEmpty) return 0;
    double total = 0;
    int count = 0;
    for (final packProgress in _allPacksProgress.values) {
      if (packProgress.containsKey(method)) {
        total += packProgress[method]!;
        count++;
      }
    }
    return count > 0 ? total / count : 0;
  }

  double getPackOverallProgress(String packId) =>
      _packProgress[packId] ?? 0.0;

  double getMethodProgressForPack(String packId, String method) =>
      _allPacksProgress[packId]?[method] ?? 0.0;

  int getStudyTimeForPack(String packId) => _packStudyTime[packId] ?? 0;

  void startCourseTimer(String packId) {
    _currentTimerPackId = packId;
    _courseTimer = Stopwatch()..start();
  }

  Future<void> stopCourseTimer() async {
    if (_courseTimer != null && _currentTimerPackId != null) {
      final elapsed = _courseTimer!.elapsedMilliseconds;
      final id = _currentTimerPackId!;
      final total = (_packStudyTime[id] ?? 0) + elapsed;
      _packStudyTime[id] = total;
      _totalStudyTime += elapsed;
      final sp = _prefs ?? await SharedPreferences.getInstance();
      await sp.setInt('study_time_$id', total);
      await sp.setInt('totalStudyTime', _totalStudyTime);
    }
    _courseTimer = null;
    _currentTimerPackId = null;
    notifyListeners();
  }

  bool get hasTranscript => (_rawText ?? '').trim().isNotEmpty;

  bool get hasAnalysis =>
      (summary?.isNotEmpty ?? false) ||
      _flashcards.isNotEmpty ||
      _listNotEmpty(_deepPrompts) ||
      _listNotEmpty(_conceptGroups) ||
      _conceptTopics.isNotEmpty ||
      _quizzes.isNotEmpty ||
      _cloze.isNotEmpty;

  /// Whether there is enough data to save
  bool get canSavePack =>
      (summary?.trim().isNotEmpty ?? false) ||
      deepPrompts.isNotEmpty ||
      conceptGroups.isNotEmpty ||
      conceptTopics.isNotEmpty ||
      flashcards.isNotEmpty ||
      _cloze.isNotEmpty;

  // Convenience flags for content availability
  bool get hasMemorization => _flashcards.isNotEmpty;
  bool get hasQuiz => _quizzes.isNotEmpty;
  bool get hasCloze => _cloze.isNotEmpty;

  set content(String? v) {
    _content = v;
    notifyListeners();
  }

  set rawText(String? v) {
    _rawText = v;
    _updateSegments();
    notifyListeners();
  }

  void setTranscript(String text) {
    _rawText = text.trim();
    _lastError = null;
    _updateSegments();
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

  void _updateSegments() {
    final text = (summary?.trim().isNotEmpty ?? false)
        ? summary!.trim()
        : (_rawText ?? '').trim();
    _textSegments = text
        .split(RegExp(r'\n{2,}'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _resetDeepProgress() {
    final len = _deepPrompts?.length ?? 0;
    _deepResponses = List.filled(len, '');
    _deepCompleted = List.filled(len, false);
    _deepIndex = 0;
    _deepDone = false;
  }

  Future<void> _saveProgress() async {
    if (_contentHash.isEmpty) return;
    final sp = _prefs ?? await SharedPreferences.getInstance();
    await sp.setInt('$_contentHash/flashIndex', _flashIndex);
    await sp.setInt('$_contentHash/deepIndex', _deepIndex);
    await sp.setBool('$_contentHash/deepDone', _deepDone);
    await sp.setStringList('$_contentHash/deepResponses', _deepResponses);
    await sp.setStringList(
        '$_contentHash/deepCompleted',
        _deepCompleted.map((e) => e ? '1' : '0').toList());
    await sp.setInt('$_contentHash/quizScore', _quizScore);
    await sp.setString('$_packId/methodTime', json.encode(_methodTime));
    for (final e in _methodProgress.entries) {
      await sp.setDouble('progress_${_packId}_${e.key}', e.value);
      _allPacksProgress[_packId] ??= {};
      _allPacksProgress[_packId]![e.key] = e.value;
    }
    for (final e in _cumulativeMethodTime.entries) {
      await sp.setInt('cumulative_${e.key}', e.value);
    }
    await sp.setInt('totalStudyTime', _totalStudyTime);
    await sp.setInt('completedSessions', _completedSessions);
    await sp.setDouble('overall_progress_${_packId}', overallProgress);
    _packProgress[_packId] = overallProgress;
    await sp.setInt('study_time_${_packId}', _packStudyTime[_packId] ?? 0);
  }

  Future<void> _loadProgress() async {
    if (_contentHash.isEmpty) return;
    final sp = _prefs ?? await SharedPreferences.getInstance();
    _flashIndex = sp.getInt('$_contentHash/flashIndex') ?? 0;
    _deepIndex = sp.getInt('$_contentHash/deepIndex') ?? 0;
    _deepDone = sp.getBool('$_contentHash/deepDone') ?? false;
    _deepResponses =
        sp.getStringList('$_contentHash/deepResponses') ?? _deepResponses;
    final comp = sp.getStringList('$_contentHash/deepCompleted') ?? [];
    _deepCompleted = comp.map((e) => e == '1').toList();
    final len = _deepPrompts?.length ?? 0;
    if (_deepResponses.length < len) {
      _deepResponses.addAll(List.filled(len - _deepResponses.length, ''));
    } else if (_deepResponses.length > len) {
      _deepResponses = _deepResponses.sublist(0, len);
    }
    if (_deepCompleted.length < len) {
      _deepCompleted.addAll(List.filled(len - _deepCompleted.length, false));
    } else if (_deepCompleted.length > len) {
      _deepCompleted = _deepCompleted.sublist(0, len);
    }
    _quizScore = sp.getInt('$_contentHash/quizScore') ?? 0;

    _methodProgress
      ..clear()
      ..addAll({
        for (final m in ['flash', 'deep', 'concept', 'quiz', 'cloze'])
          if (sp.getDouble('progress_${_packId}_$m') != null)
            m: sp.getDouble('progress_${_packId}_$m')!
      });
    final mt = sp.getString('$_packId/methodTime');
    _methodTime
      ..clear()
      ..addAll(mt != null
          ? (json.decode(mt) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num).toInt()))
          : {});
    _totalStudyTime = sp.getInt('totalStudyTime') ?? _totalStudyTime;
    _completedSessions = sp.getInt('completedSessions') ?? _completedSessions;
    _packProgress[_packId] = sp.getDouble('overall_progress_${_packId}') ??
        _packProgress[_packId] ?? 0;
    _packStudyTime[_packId] =
        sp.getInt('study_time_${_packId}') ?? _packStudyTime[_packId] ?? 0;
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

  List<ClozeItem> _coerceCloze(dynamic raw) {
    final list = (raw as List? ?? []);
    return list
        .map((e) => ClozeItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<String> _tokenize(String s) {
    return s
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  double _topicSimilarity(String a, String b) {
    final aTokens = _tokenize(a);
    final bTokens = _tokenize(b);
    if (aTokens.isEmpty || bTokens.isEmpty) return 0;
    final aSet = aTokens.toSet();
    final bSet = bTokens.toSet();
    final inter = aSet.intersection(bSet).length;
    final union = aSet.union(bSet).length;
    return union == 0 ? 0 : inter / union;
  }

  List<ConceptGroup> _autoGroupTopics(List<String> topics) {
    final groups = <ConceptGroup>[];
    final used = <String>{};
    for (final t in topics) {
      if (used.contains(t)) continue;
      final gt = <String>[t];
      used.add(t);
      for (final o in topics) {
        if (used.contains(o)) continue;
        final sim = _topicSimilarity(t, o);
        if (sim >= 0.5 || t.contains(o) || o.contains(t)) {
          gt.add(o);
          used.add(o);
        }
      }
      groups.add(ConceptGroup(title: gt.first, topics: gt));
    }

    const maxGroups = 5;
    if (groups.length > maxGroups) {
      final sorted = [...topics]..sort();
      groups
        ..clear()
        ..addAll(List.generate(maxGroups, (i) {
          final size = (sorted.length / maxGroups).ceil();
          final start = i * size;
          if (start >= sorted.length) {
            return ConceptGroup(title: 'Group ${i + 1}', topics: const []);
          }
          final end = math.min(start + size, sorted.length);
          return ConceptGroup(
            title: sorted[start],
            topics: sorted.sublist(start, end),
          );
        }).where((g) => g.topics?.isNotEmpty ?? false));
    }

    return groups;
  }

  ConceptMapData _buildConceptMap(List<ConceptGroup> groups,
      {String root = 'Topics'}) {
    final nodes = <String>[root];
    final relations = <Map<String, String>>[];
    for (final g in groups) {
      nodes.add(g.title);
      relations.add({'from': root, 'to': g.title});
      for (final t in g.topics ?? []) {
        nodes.add(t);
        relations.add({'from': g.title, 'to': t});
      }
    }
    return ConceptMapData(groups: groups, nodes: nodes, relations: relations);
  }

  ConceptMapData _parseConceptMap(dynamic cm) {
    if (cm is Map && cm['groups'] is List) {
      final parsed = <ConceptGroup>[];
      for (final g in cm['groups'] as List) {
        final m = (g as Map?) ?? const {};
        final title = (m['title'] ?? m['group'] ?? 'Topics').toString();
        if (title.trim().startsWith('Definition:')) continue;
        final topics = ((m['topics'] as List?) ?? const [])
            .map((t) => t.toString())
            .where(
              (t) => t.trim().isNotEmpty && !t.trim().startsWith('Definition:'),
            )
            .toList();
        if (topics.isEmpty) continue;
        parsed.add(ConceptGroup(title: title, topics: topics));
      }
      if (parsed.length == 1 && parsed.first.title == 'Topics') {
        final auto = _autoGroupTopics(parsed.first.topics ?? []);
        return _buildConceptMap(auto);
      }
      return _buildConceptMap(parsed);
    } else if (cm is List) {
      final topics = cm
          .map((t) => t.toString())
          .where(
            (t) => t.trim().isNotEmpty && !t.trim().startsWith('Definition:'),
          )
          .toList();
      final auto = _autoGroupTopics(topics);
      return _buildConceptMap(auto);
    }

    return ConceptMapData(groups: [], nodes: [], relations: []);
  }

  // --- Selection helpers ---
  void setSelectedAudio(({Uint8List bytes, String name}) f) {
    _selectedAudio = f;
    _selectedVideo = null;
    _rawText = null;
    _content = null;
    _lastError = null;
    _canContinue = false;
    notifyListeners();
  }

  void setSelectedVideo(({Uint8List bytes, String name}) f) {
    _selectedVideo = f;
    _selectedAudio = null;
    _rawText = null;
    _content = null;
    _lastError = null;
    _canContinue = false;
    notifyListeners();
  }

  Future<bool>? _inflightAnalysis;

  Future<bool> runAnalysis(BuildContext context) {
    _inflightAnalysis ??= _runAnalysisInternal(context);
    return _inflightAnalysis!;
  }

  Future<void> _runOfflineAnalysis(String text) async {
    if (!Env.enableOfflineLLM) return;
    final provider = _pLocal!;
    _conceptGroups = [];
    _conceptTopics = [];
    _conceptNodes = [];
    _conceptRelations = [];
    _summary = await offlineSummarize(provider, text);
    await _fillPackFromHeuristicIfMissing(
      transcript: text,
      summary: _summary ?? text,
    );
    final cards = await offlineFlashcards(provider, text);
    _flashcards
      ..clear()
      ..addAll(
        cards.map(
          (c) => Flashcard(term: c['q'] ?? '', definition: c['a'] ?? ''),
        ),
      );
    debugPrint('Received flashcards: ${_flashcards.length}');
    _quizzes.clear();
    _cloze.clear();
    _deepPrompts = [];
    _resetDeepProgress();
    _updateSegments();

    _canContinue =
        (_summary?.trim().isNotEmpty ?? false) || _flashcards.isNotEmpty;
    final baseForHash = (_summary?.trim().isNotEmpty ?? false)
        ? _summary!.trim()
        : _flashcards.map((f) => f.term).join('|');
    _contentHash = baseForHash.isNotEmpty ? _hash(baseForHash) : '';
    await _loadProgress();
    await _saveProgress();
    await SyncQueue.enqueue(
      kind: 'upgrade_summary',
      sourceText: text,
      learnPackId: _packId,
    );
    await SyncQueue.enqueue(
      kind: 'upgrade_flashcards',
      sourceText: text,
      learnPackId: _packId,
    );
    if (_canContinue) {
      await saveCurrentPack();
      debugPrint('[LLM] Study pack auto-saved');
    }
  }

  Future<void> _runHeuristicAnalysis(String text) async {
    final buf = StringBuffer();
    await for (final t in _heu!.stream(text)) {
      buf.write(t);
    }
    final raw = buf.toString();

    final summaryMatch =
        RegExp(r'### Resumen \(heurístico\)\n((?:- .*\n)+)').firstMatch(raw);
    final summaryLines = summaryMatch != null
        ? RegExp(r'^- (.*)\$', multiLine: true)
            .allMatches(summaryMatch.group(1)!)
            .map((m) => m.group(1)!.trim())
            .toList()
        : <String>[];
    _summary = summaryLines.join('\n');

    final keywordMatch =
        RegExp(r'### Palabras clave\n((?:• .*\n)+)').firstMatch(raw);
    final keywords = keywordMatch != null
        ? RegExp(r'^• (.*)\$', multiLine: true)
            .allMatches(keywordMatch.group(1)!)
            .map((m) => m.group(1)!.trim())
            .toList()
        : <String>[];
    _flashcards
      ..clear()
      ..addAll(keywords.map((k) => Flashcard(term: k, definition: '')));
    debugPrint('Received flashcards: ${_flashcards.length}');

    final clozeMatch =
        RegExp(r'### Cloze.*?\n((?:• .*\n?)*)', dotAll: true).firstMatch(raw);
    final clozeLines = clozeMatch != null
        ? RegExp(r'^• (.*)\$', multiLine: true)
            .allMatches(clozeMatch.group(1)!)
            .map((m) => m.group(1)!.trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];
    _cloze
      ..clear()
      ..addAll(
        clozeLines
            .map((c) => ClozeItem(sentence: c, options: const [], answerIndex: 0)),
      );

    _quizzes.clear();
    _deepPrompts = [];
    _resetDeepProgress();
    _updateSegments();

    _canContinue =
        (_summary?.trim().isNotEmpty ?? false) || _flashcards.isNotEmpty;
    final baseForHash = (_summary?.trim().isNotEmpty ?? false)
        ? _summary!.trim()
        : _flashcards.map((f) => f.term).join('|');
    _contentHash = baseForHash.isNotEmpty ? _hash(baseForHash) : '';
    await _loadProgress();
    await _saveProgress();
    if (_canContinue) {
      await saveCurrentPack();
      debugPrint('[LLM] Study pack auto-saved');
    }
  }

  Future<void> _fillPackFromHeuristicIfMissing({
    required String transcript,
    required String summary,
  }) async {
    final baseText = summary.isNotEmpty ? summary : transcript;
    if (baseText.trim().isEmpty) return;

    final needFlash = _flashcards.isEmpty;
    final needConcepts =
        _conceptGroups == null || _conceptGroups!.isEmpty ||
        _conceptNodes.isEmpty ||
        _conceptRelations.isEmpty;
    final needQuiz = _quizzes.isEmpty;
    final needCloze =
        _cloze.isEmpty || _cloze.any((c) => c.options.isEmpty);
    final needDeep = _deepPrompts == null || _deepPrompts!.isEmpty;

    if (!(needFlash || needConcepts || needQuiz || needCloze || needDeep))
      return;

    final h = _heu ??= HeuristicOfflineLLMProvider();
    var used = false;

    if (needFlash) {
      final maps = await h.generateFlashcards(baseText);
      _flashcards
        ..clear()
        ..addAll(_coerceFlashcards(maps));
      debugPrint('Received flashcards: ${_flashcards.length}');
      used = used || maps.isNotEmpty;
    }
    if (needConcepts) {
      final cgSource = transcript.isNotEmpty ? transcript : baseText;
      final cg = await h.generateConceptGraph(cgSource);
      final cmap = _parseConceptMap(cg);
      _conceptGroups = cmap.groups;
      _conceptNodes = cmap.nodes;
      _conceptRelations = cmap.relations;
      used = true;
    }
    if (needQuiz) {
      final maps = await h.generateQuiz(baseText);
      _quizzes
        ..clear()
        ..addAll(_coerceQuiz(maps));
      used = used || maps.isNotEmpty;
    }
    if (needCloze) {
      final maps = await h.generateCloze(baseText);
      _cloze
        ..clear()
        ..addAll(_coerceCloze(maps));
      used = used || maps.isNotEmpty;
    }
    if (needDeep) {
      final maps = await h.generateDeepPrompts(baseText);
      _deepPrompts = maps
          .map((m) => DeepPrompt.fromMap(m))
          .where((p) => p.prompt.trim().isNotEmpty)
          .toList();
      _resetDeepProgress();
      used = used || _deepPrompts!.isNotEmpty;
    }

    if (used) {
      debugPrint(
          '[LLM] backend delivered minimal set; heuristic completed study pack');
    }

    notifyListeners();
  }

  Future<void> applyAnalyzeResult(AnalyzeResult r) async {
    _rawText = r.transcript;
    _summary = r.summary;
    _content = r.summary.isNotEmpty ? r.summary : r.transcript;
    _tags = r.tags;
    _deepPrompts = r.deepPrompts
        .map((m) => DeepPrompt.fromMap(m))
        .where((p) => p.prompt.trim().isNotEmpty)
        .toList();
    _resetDeepProgress();
    _updateSegments();

    await _fillPackFromHeuristicIfMissing(
      transcript: r.transcript,
      summary: r.summary,
    );
  }

  Future<void> _runBackendAnalysis(String text, BuildContext context) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/analyze');
    final timeout = context.read<SettingsProvider>().backendTimeout;
    final resp = await BackendClient.client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text, 'llm_provider': 'backend'}),
        )
        .timeout(timeout);

    final bodyText = utf8.decode(resp.bodyBytes);
    if (resp.statusCode != 200) {
      debugPrint('[analyze] HTTP ${resp.statusCode}: $bodyText');
      _lastError = 'HTTP ${resp.statusCode}';
      throw Exception('HTTP ${resp.statusCode}');
    }

    final data = mapifyResponse(bodyText);
    final ok = (data['ok'] == true) || (data['status'] == 'ok');
    if (!ok) {
      debugPrint('[analyze] not ok: $bodyText');
      _lastError = (data['error'] ?? 'Analyze returned not ok').toString();
      throw Exception(_lastError);
    }

    _flashcards
      ..clear()
      ..addAll(_coerceFlashcards(data['flashcards'] ?? data['cards']));
    debugPrint('Received flashcards: ${_flashcards.length}');
    _quizzes
      ..clear()
      ..addAll(_coerceQuiz(data['quiz'] ?? data['quizzes']));
    _cloze
      ..clear()
      ..addAll(_coerceCloze(data['cloze']));
    final cmap = _parseConceptMap(data['concept_map']);
    _conceptGroups = cmap.groups;
    _conceptNodes = cmap.nodes;
    _conceptRelations = cmap.relations;

    final result = AnalyzeResult.fromJson(data);
    await applyAnalyzeResult(result);

    final groups = _conceptGroups ?? [];
    _conceptTopics = (groups.length == 1 && groups.first.title == 'Topics')
        ? (groups.first.topics ?? [])
        : [];

    _canContinue = (_summary?.trim().isNotEmpty ?? false) ||
        _flashcards.isNotEmpty ||
        _quizzes.isNotEmpty ||
        _cloze.isNotEmpty ||
        groups.isNotEmpty;

    final baseForHash = (_summary?.trim().isNotEmpty ?? false)
        ? _summary!.trim()
        : _flashcards.map((f) => f.term).join('|');

    _contentHash = baseForHash.isNotEmpty ? _hash(baseForHash) : '';
    await _loadProgress();
    await _saveProgress();
    if (_canContinue) {
      await saveCurrentPack();
      debugPrint('[LLM] Study pack auto-saved');
    }
    notifyListeners();
  }

  Future<void> _analyzeWith(
      LLMProvider provider, String text, BuildContext context) async {
    if (provider.id == 'backend') {
      await _runBackendAnalysis(text, context);
    } else if (provider.id == 'offline' && Env.enableOfflineLLM) {
      await _runOfflineAnalysis(text);
    } else {
      await _runHeuristicAnalysis(text);
    }
  }

  Future<bool> _runAnalysisInternal(BuildContext context) async {
    if (_isAnalyzing) return _canContinue;

    _isAnalyzing = true;
    _lastError = null;
    _flashcards.clear();
    _flashIndex = 0;
    notifyListeners();

    try {
      // Ensure we have text to analyze, transcribing if necessary.
      String text =
          (_rawText?.trim().isNotEmpty == true ? _rawText! : _content ?? '')
              .trim();
      if (text.isEmpty && _selectedAudio != null) {
        text = await TranscriptionService().sendFileOrExtractLocally(
          bytes: _selectedAudio!.bytes,
          filename: _selectedAudio!.name,
        );
        _rawText = text;
        _content = text;
      } else if (text.isEmpty && _selectedVideo != null) {
        text = await TranscriptionService().sendFileOrExtractLocally(
          bytes: _selectedVideo!.bytes,
          filename: _selectedVideo!.name,
        );
        _rawText = text;
        _content = text;
      }

      text = text.trim();
      if (text.isEmpty) {
        _lastError = 'Nothing to analyze.';
        return false;
      }

      await _ensureProviders();
      final settings = context.read<SettingsProvider>();
      final offlinePref = Env.enableOfflineLLM && settings.enableOfflineLLM;
      final net = await hasInternet();

      LLMProvider primary;
      if (offlinePref) {
        final ready = Env.enableOfflineLLM && OfflineLLM.instance.isReady;
        primary = ready ? _pLocal! : _heu!;
      } else {
        if (net) {
          primary = _pBack!;
        } else {
          final ready =
              Env.enableOfflineLLM && OfflineLLM.instance.isReady;
          primary = ready ? _pLocal! : _heu!;
        }
      }

      currentRunInfo.value = RunInfo(primary.id, offlinePref, net, DateTime.now());
      debugPrint('[LLM] start provider=${primary.id} net=$net offlinePref=$offlinePref');
      final sw = Stopwatch()..start();
      try {
        await _analyzeWith(primary, text, context);
        await saveCurrentPack();
        _justSaved = true;
        sw.stop();
        debugPrint('[LLM] done provider=${primary.id} ms=${sw.elapsedMilliseconds}');
        return _canContinue;
      } catch (e) {
        sw.stop();
        debugPrint('[LLM] error provider=${primary.id} ms=${sw.elapsedMilliseconds} err=$e');

        final chain = <LLMProvider>[];
        if (primary != _pBack && net) chain.add(_pBack!);
        if (primary != _pLocal &&
            Env.enableOfflineLLM &&
            OfflineLLM.instance.isReady) {
          chain.add(_pLocal!);
        }
        if (primary != _heu) chain.add(_heu!);

        for (final alt in chain) {
          try {
            currentRunInfo.value = RunInfo(alt.id, offlinePref, net, DateTime.now());
            debugPrint('[LLM] fallback -> ${alt.id}');
            await _analyzeWith(alt, text, context);
            await saveCurrentPack();
            _justSaved = true;
            debugPrint('[LLM] fallback ok ${alt.id}');
            return _canContinue;
          } catch (e2) {
            debugPrint('[LLM] fallback fail ${alt.id} err=$e2');
            continue;
          }
        }
        _lastError = e.toString();
        if (_lastError?.contains('file_too_large') == true) {
          _lastError = 'file_too_large';
        }
        return false;
      }
    } finally {
      _isAnalyzing = false;
      _inflightAnalysis = null;
      notifyListeners();
    }
  }

  // Legacy helpers used by older flows.
  Future<void> transcribeAndAnalyze(
      ({Uint8List bytes, String name}) file, BuildContext context) async {
    setSelectedAudio(file);
    await runAnalysis(context);
  }

  void resetTranscribeFlow() {
    resetAll();
  }

  // --- Progress mutations ---
  void setFlashIndex(int idx) {
    _flashIndex = idx.clamp(
      0,
      _flashcards.isEmpty ? 0 : _flashcards.length - 1,
    );
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

  void submitDeepResponse(String response) {
    if (_deepPrompts == null || _deepIndex >= _deepPrompts!.length) return;
    _deepResponses[_deepIndex] = response;
    _deepCompleted[_deepIndex] = true;
    _saveProgress();
    notifyListeners();
  }

  void nextDeepPrompt() {
    if (_deepPrompts == null) return;
    if (_deepIndex < _deepPrompts!.length - 1) {
      _deepIndex++;
    } else {
      _deepDone = true;
    }
    _saveProgress();
    notifyListeners();
  }

  void saveQuizScore(int score) {
    _quizScore = score;
    _saveProgress();
    notifyListeners();
  }

  // --- Study session tracking ---
  void startStudySession(String method) {
    _sessionStart = DateTime.now();
  }

  void endStudySession(String method) {
    if (_sessionStart != null) {
      final elapsed = DateTime.now().difference(_sessionStart!).inMilliseconds;
      _methodTime[method] = (_methodTime[method] ?? 0) + elapsed;
      _cumulativeMethodTime[method] =
          (_cumulativeMethodTime[method] ?? 0) + elapsed;
      _totalStudyTime += elapsed;
      _sessionStart = null;
      Future.microtask(() => _saveProgress());
    }
  }

  void updateMethodProgress(String method, double progress,
      {bool notify = true}) {
    _methodProgress[method] = progress.clamp(0.0, 1.0);

    _allPacksProgress[_packId] ??= {};
    _allPacksProgress[_packId]![method] = _methodProgress[method]!;

    if (progress >= 0.8) _completedSessions++;

    Future.microtask(() async {
      final sp = _prefs ?? await SharedPreferences.getInstance();
      await sp.setDouble('$_packId/methodProgress/$method',
          _methodProgress[method]!);
      await sp.setInt('cumulative_$method',
          _cumulativeMethodTime[method] ?? 0);
      _packProgress[_packId] = overallProgress;
      await sp.setDouble('packProgress/$_packId', overallProgress);

      if (notify) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    });
  }

  double getMethodProgress(StudyMode mode) {
    switch (mode) {
      case StudyMode.memorization:
        return flashcards.isEmpty ? 0 : (_flashIndex + 1) / flashcards.length;
      case StudyMode.deep_understanding:
        return deepPrompts.isEmpty
            ? 0
            : deepCompleted.where((c) => c).length / deepPrompts.length;
      case StudyMode.contextual_association:
        return _methodProgress['concept'] ?? 0;
      case StudyMode.interactive_evaluation:
        return quizzes.isEmpty ? 0 : _methodProgress['quiz'] ?? 0;
    }
  }

  /// Compute a stable content hash
  String _computeHash() {
    final base = jsonEncode({
      's': summary,
      'rt': rawText,
      'f': flashcards.map((e) => {'t': e.term, 'd': e.definition}).toList(),
      'dp': deepPrompts.map((e) => {'p': e.prompt, 'h': e.hint}).toList(),
      'cg': conceptGroups
          .map((g) => {'t': g.title, 'x': g.topics ?? const []})
          .toList(),
      'ct': conceptTopics,
      'cn': conceptNodes,
      'cr': conceptRelations,
      'cl': cloze
          .map((c) => {'s': c.sentence, 'o': c.options, 'a': c.answerIndex})
          .toList(),
    });
    return base.hashCode.toUnsigned(32).toRadixString(16);
  }

  /// Build JSON map to persist
  Map<String, dynamic> buildStudyPack() {
    final hash = _computeHash();
    return {
      'id': _packId,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'contentHash': hash,
      'summary': summary ?? '',
      'flashcards': flashcards
          .map((f) => {'term': f.term, 'definition': f.definition})
          .toList(),
      // Save deep prompts in both camelCase and snake_case for backward
      // compatibility with earlier app versions.
      'deepPrompts': deepPrompts
          .map((d) => {'prompt': d.prompt, 'hint': d.hint})
          .toList(),
      'deep_prompts': deepPrompts
          .map((d) => {'prompt': d.prompt, 'hint': d.hint})
          .toList(),
      'conceptGroups': conceptGroups
          .map((g) => {'title': g.title, 'topics': g.topics ?? const []})
          .toList(),
      'conceptTopics': conceptTopics,
      'conceptNodes': conceptNodes,
      'conceptRelations': conceptRelations,
      'rawText': rawText ?? '',
      'quiz': quizzes
          .map(
            (q) => {
              'question': q.question,
              'options': q.options,
              'answerIndex': q.answerIndex,
            },
          )
          .toList(),
      'cloze': cloze
          .map(
            (c) => {
              'sentence': c.sentence,
              'options': c.options,
              'answerIndex': c.answerIndex,
            },
          )
          .toList(),
    };
  }

  /// Hydrate provider from a saved pack (no network)
  Future<void> hydrateFromPack(Map<String, dynamic> p) async {
    _summary = (p['summary'] ?? '').toString();
    _rawText = (p['rawText'] ?? '').toString();
    _content = _summary?.isNotEmpty == true ? _summary : _rawText;
    _updateSegments();

    _flashcards
      ..clear()
      ..addAll(
        ((p['flashcards'] as List?) ?? const []).map(
          (e) => Flashcard(
            term: (e['term'] ?? '').toString(),
            definition: (e['definition'] ?? '').toString(),
          ),
        ),
      );

    final rawDeep = (p['deepPrompts'] ?? p['deep_prompts'] ?? []) as List?;
    _deepPrompts = rawDeep
        ?.map(
          (e) => DeepPrompt(
            prompt: (e['prompt'] ?? '').toString(),
            hint: (e['hint'] ?? '').toString(),
          ),
        )
        .where((d) => d.prompt.trim().isNotEmpty)
        .toList();
    _deepPrompts ??= [];
    _resetDeepProgress();

    _conceptGroups = ((p['conceptGroups'] as List?) ?? const [])
        .map(
          (e) => ConceptGroup(
            title: (e['title'] ?? 'Topics').toString(),
            topics: ((e['topics'] as List?) ?? const [])
                .map((t) => '$t')
                .toList(),
          ),
        )
        .toList();

    _conceptTopics = ((p['conceptTopics'] as List?) ?? const [])
        .map((t) => '$t')
        .toList();
    _conceptNodes = ((p['conceptNodes'] as List?) ?? const [])
        .map((n) => '$n')
        .toList();
    _conceptRelations = ((p['conceptRelations'] as List?) ?? const [])
        .map((e) =>
            Map<String, String>.from(e.map((k, v) => MapEntry('$k', '$v'))))
        .toList();

    if (_conceptNodes.isEmpty || _conceptRelations.isEmpty) {
      // Reconstruct concept map nodes/relations from stored groups/topics
      final rawMap = (_conceptGroups != null && _conceptGroups!.isNotEmpty)
          ? {
              'groups': _conceptGroups!
                  .map((g) => {'title': g.title, 'topics': g.topics})
                  .toList()
            }
          : _conceptTopics;
      final cmap = _parseConceptMap(rawMap);
      if (_conceptNodes.isEmpty) _conceptNodes = cmap.nodes;
      if (_conceptRelations.isEmpty) _conceptRelations = cmap.relations;
    }

    _quizzes
      ..clear()
      ..addAll(
        ((p['quiz'] as List?) ?? const []).map(
          (e) => QuizItem.fromMap(Map<String, dynamic>.from(e)),
        ),
      );
    _cloze
      ..clear()
      ..addAll(
        ((p['cloze'] as List?) ?? const []).map(
          (e) => ClozeItem.fromMap(Map<String, dynamic>.from(e)),
        ),
      );

    _packId = (p['id'] ?? _packId).toString();
    _contentHash = (p['contentHash'] ?? '').toString();
    await _loadProgress();

    _lastError = null;
    _isAnalyzing = false;
    notifyListeners();
  }

  /// Persist current pack
  Future<void> saveCurrentPack() async {
    if (!canSavePack) return;
    final box = Hive.box<Map>('learnpacks');
    final pack = buildStudyPack();
    await box.put(pack['id'] as String, Map<String, dynamic>.from(pack));
  }

  /// Reload stored packs and sync progress values
  Future<void> refreshPacks() async {
    final box = await Hive.openBox<Map>('learnpacks');
    for (final e in box.values) {
      final m = Map<String, dynamic>.from(e);
      final id = (m['id'] ?? '').toString();
      final prog = m['progress'];
      if (prog != null) {
        final parsed = double.tryParse(prog.toString());
        if (parsed != null) {
          final norm = parsed > 1 ? parsed / 100 : parsed;
          _packProgress[id] = norm;
          await _prefs?.setDouble('overall_progress_$id', norm);
        }
      }
    }
    notifyListeners();
  }

  /// List saved packs
  List<Map<String, dynamic>> listPacks() {
    final box = Hive.box<Map>('learnpacks');
    return box.values
        .map((e) => Map<String, dynamic>.from(e))
        .map((m) {
          final id = (m['id'] ?? '').toString();
          if (!m.containsKey('progress')) {
            final prog = _packProgress[id] ?? 0.0;
            m['progress'] = (prog * 100).toStringAsFixed(1);
          }
          return m;
        })
        .sorted(
          (a, b) => (b['createdAt'] ?? '').toString().compareTo(
            (a['createdAt'] ?? '').toString(),
          ),
        )
        .toList();
  }

  /// Retrieve the display name for a study pack by ID, prioritizing any
  /// user-provided name or title before falling back to an autogenerated one.
  String getPackDisplayName(String packId) {
    final box = Hive.box<Map>('learnpacks');
    final pack = box.get(packId);
    if (pack == null) return 'Study Pack';
    return getDisplayName(Map<String, dynamic>.from(pack));
  }

  /// Delete by id
  Future<void> deletePack(String id) async {
    final box = Hive.box<Map>('learnpacks');
    await box.delete(id);
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
    _tags = [];
    _flashcards.clear();
    _deepPrompts = null;
    _deepResponses = [];
    _deepCompleted = [];
    _conceptGroups = null;
    _conceptTopics = [];
    _conceptNodes = [];
    _conceptRelations = [];
    _quizzes.clear();
    _cloze.clear();
    _flashIndex = 0;
    _deepIndex = 0;
    _deepDone = false;
    _textSegments = [];
    _quizScore = 0;
    _contentHash = '';
    _packId = const Uuid().v4();
    _methodProgress.clear();
    _methodTime.clear();
    // _allPacksProgress and _cumulativeMethodTime are preserved
    _sessionStart = null;

    if (notify) {
      // Defer notification until the next frame to avoid calling listeners
      // while the widget tree is locked during dispose.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
}
