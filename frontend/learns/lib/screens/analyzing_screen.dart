import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../content_provider.dart';

class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<ContentProvider>().ensureAnalysisStarted());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    final busy = p.isAnalyzing;
    final canGo = p.canContinue;

    return Scaffold(
      appBar: AppBar(title: const Text('Analyzing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (busy) const LinearProgressIndicator(),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canGo
                    ? () => Navigator.of(context)
                        .pushNamed(AppRoutes.studyPack)
                    : null,
                child: Text(canGo ? 'Continue' : 'Analyzing...'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
