// lib/core/sync/sync_manager.dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../llm/llm_router.dart';
import '../llm/offline_tasks.dart';
import 'sync_queue.dart';
import 'sync_models.dart';

class SyncManager {
  final LLMRouter router;
  StreamSubscription? _sub;
  bool _running = false;

  SyncManager(this.router);

  Future<void> start() async {
    await SyncQueue.init();
    _sub = Connectivity().onConnectivityChanged.listen((_) => _kick());
    _kick();
  }

  Future<void> _kick() async {
    if (_running) return;
    _running = true;
    try {
      final tasks =
          List<SyncTask>.from(SyncQueue.all().where((t) => t.status == 'queued'));
      for (final t in tasks) {
        // only run if we have internet (router will choose replicate)
        final stream = router.stream(_promptFor(t), maxTokens: 256, temperature: .2);
        t.status = 'running';
        await SyncQueue.update(t);

        final buf = StringBuffer();
        await for (final tok in stream) {
          buf.write(tok);
        }
        final out = buf.toString();

        // TODO: actualizar LearnPack/Sección con 'out'
        // saveToLearnPack(t.learnPackId, t.kind, out);

        t.status = 'done';
        t.error = null;
        await SyncQueue.update(t);
      }
    } catch (e) {
      // mark last as error if needed
    } finally {
      _running = false;
    }
  }

  String _promptFor(SyncTask t) {
    switch (t.kind) {
      case 'upgrade_summary':
        return 'You are a tutor. Summarize into 5 bullet points, Spanish:\n\n${t.sourceText}';
      case 'upgrade_flashcards':
        return 'Crea 6 flashcards en JSON [{"q":"...","a":"..."}] en español. Texto:\n\n${t.sourceText}';
      default:
        return t.sourceText;
    }
  }

  Future<void> dispose() async => _sub?.cancel();
}
