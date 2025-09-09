import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CourseProgress {
  final String courseId;
  final int totalItems;
  final int completed;
  final int correct;
  final int timeMs; // tiempo dedicado acumulado
  const CourseProgress({
    required this.courseId,
    required this.totalItems,
    required this.completed,
    required this.correct,
    required this.timeMs,
  });

  double get pct => totalItems == 0 ? 0 : completed / totalItems;
  double get accuracy => completed == 0 ? 0 : correct / completed;

  Map<String, dynamic> toJson() => {
    'courseId': courseId,
    'total': totalItems,
    'done': completed,
    'ok': correct,
    'timeMs': timeMs,
  };

  factory CourseProgress.fromJson(Map<String, dynamic> j) => CourseProgress(
    courseId: j['courseId'],
    totalItems: j['total'],
    completed: j['done'],
    correct: j['ok'],
    timeMs: j['timeMs'],
  );
}

class ProgressService {
  static const _k = 'progress.v1';
  final SharedPreferences _prefs;
  ProgressService(this._prefs);

  Map<String, CourseProgress> _cache = {};

  static Future<ProgressService> create() async {
    final p = await SharedPreferences.getInstance();
    final s = ProgressService(p);
    s._load();
    return s;
  }

  void _load() {
    final raw = _prefs.getString(_k);
    if (raw == null) return;
    final Map<String, dynamic> j = json.decode(raw);
    _cache = j.map((k, v) => MapEntry(k, CourseProgress.fromJson(v)));
  }

  void _save() {
    final j = _cache.map((k, v) => MapEntry(k, v.toJson()));
    _prefs.setString(_k, json.encode(j));
  }

  CourseProgress get(String courseId) =>
      _cache[courseId] ?? CourseProgress(courseId: courseId, totalItems: 0, completed: 0, correct: 0, timeMs: 0);

  void startRun(String courseId, {required int totalItems}) {
    _cache[courseId] = CourseProgress(courseId: courseId, totalItems: totalItems, completed: 0, correct: 0, timeMs: 0);
    _save();
  }

  void recordAnswer(String courseId, {required bool correct}) {
    final cur = get(courseId);
    final next = CourseProgress(
      courseId: courseId,
      totalItems: cur.totalItems,
      completed: (cur.completed + 1).clamp(0, cur.totalItems),
      correct: cur.correct + (correct ? 1 : 0),
      timeMs: cur.timeMs,
    );
    _cache[courseId] = next;
    _save();
  }

  void addTime(String courseId, int deltaMs) {
    final cur = get(courseId);
    _cache[courseId] = CourseProgress(
      courseId: courseId,
      totalItems: cur.totalItems,
      completed: cur.completed,
      correct: cur.correct,
      timeMs: cur.timeMs + deltaMs,
    );
    _save();
  }

  void setTotal(String courseId, int total) {
    final cur = get(courseId);
    _cache[courseId] = CourseProgress(
      courseId: courseId,
      totalItems: total,
      completed: cur.completed.clamp(0, total),
      correct: cur.correct.clamp(0, total),
      timeMs: cur.timeMs,
    );
    _save();
  }

  /// Devuelve una copia inmutable del caché actual (courseId -> CourseProgress).
  Map<String, CourseProgress> snapshot() => Map.unmodifiable(_cache);
}
