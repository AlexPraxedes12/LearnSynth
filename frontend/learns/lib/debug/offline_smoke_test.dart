import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:learnsynth/services/offline_llm_compat.dart';

class OfflineSmokeTest extends StatefulWidget {
  const OfflineSmokeTest({super.key});
  @override
  State<OfflineSmokeTest> createState() => _OfflineSmokeTestState();
}

class _OfflineSmokeTestState extends State<OfflineSmokeTest> {
  String buf = '';
  @override
  void initState() {
    super.initState();
    if (!kDebugMode) return;
    () async {
      await OfflineLLM.instance.init();
      final ready = OfflineLLM.instance.isReady;
      debugPrint('[OfflineLLM] ready=$ready');
      OfflineLLM.instance.stream('hello offline').listen((t) {
        if (!mounted) return;
        setState(() => buf += t);
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline LLM smoke test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(buf.isEmpty ? '...' : buf),
      ),
    );
  }
}
