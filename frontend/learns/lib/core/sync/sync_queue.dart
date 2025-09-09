// lib/core/sync/sync_queue.dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import 'sync_models.dart';

class SyncQueue {
  static Box<Map>? _box;

  static Future<void> init() async {
    _box ??= await Hive.openBox<Map>('sync_queue');
  }

  static Future<void> enqueue({
    required String kind,
    required String sourceText,
    required String learnPackId,
  }) async {
    await init();
    final task = SyncTask(
      id: const Uuid().v4(),
      kind: kind,
      sourceText: sourceText,
      learnPackId: learnPackId,
      createdAt: DateTime.now(),
    );
    await _box!.put(task.id, task.toJson());
  }

  static Iterable<SyncTask> all() =>
      _box!.values.map((m) => SyncTask.fromJson(Map<String, dynamic>.from(m)));

  static Future<void> update(SyncTask t) async => _box!.put(t.id, t.toJson());
}
