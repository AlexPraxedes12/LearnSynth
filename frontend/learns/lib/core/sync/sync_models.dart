// lib/core/sync/sync_models.dart
import 'package:meta/meta.dart';

@immutable
class SyncTask {
  final String id; // uuid
  final String kind; // 'upgrade_summary' | 'upgrade_flashcards' | ...
  final String sourceText; // texto original
  final String learnPackId; // a qué pack/section actualizar
  final DateTime createdAt;
  String status; // 'queued' | 'running' | 'done' | 'error'
  String? error;

  SyncTask({
    required this.id,
    required this.kind,
    required this.sourceText,
    required this.learnPackId,
    required this.createdAt,
    this.status = 'queued',
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'sourceText': sourceText,
        'learnPackId': learnPackId,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'error': error,
      };

  static SyncTask fromJson(Map<String, dynamic> j) => SyncTask(
        id: j['id'] as String,
        kind: j['kind'] as String,
        sourceText: j['sourceText'] as String,
        learnPackId: j['learnPackId'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        status: j['status'] as String? ?? 'queued',
        error: j['error'] as String?,
      );
}
