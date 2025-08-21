import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content_provider.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analysis = context.watch<ContentProvider>().analysis ?? const <String, dynamic>{};
    final summary = (analysis['summary'] as String?) ?? '';
    final topics = (analysis['topics'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Study Pack')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (summary.isNotEmpty) ...[
              const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(summary),
              const SizedBox(height: 24),
            ],
            if (topics.isNotEmpty) ...[
              const Text('Topics', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...topics.map((t) => Text('• $t')),
            ],
            if (summary.isEmpty && topics.isEmpty)
              const Text('No analysis yet. Please run analysis from the previous screen.'),
          ],
        ),
      ),
    );
  }
}
