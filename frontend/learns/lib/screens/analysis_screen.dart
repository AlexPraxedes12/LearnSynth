import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    final data = p.studyPack ?? {};

    final summary = data['summary'] as String? ?? '';
    final flashcards =
        (data['flashcards'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final quiz = (data['quiz'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final conceptMap = (data['concept_map'] as List?) ?? const [];
    final spaced = (data['spaced_repetition'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Study Pack')),
      body: p.loading
          ? const Center(child: CircularProgressIndicator())
          : p.error != null
              ? Center(child: Text('Error: ${p.error}'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (summary.isNotEmpty) ...[
                        const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(summary),
                        const SizedBox(height: 16),
                      ],
                      if (flashcards.isNotEmpty) ...[
                        const Text('Flashcards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        for (final fc in flashcards)
                          Card(
                            child: ListTile(
                              title: Text(fc['term']?.toString() ?? ''),
                              subtitle: Text(fc['definition']?.toString() ?? ''),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                      if (quiz.isNotEmpty) ...[
                        const Text('Quiz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        for (final q in quiz)
                          Card(
                            child: ListTile(
                              title: Text(q['question']?.toString() ?? ''),
                              subtitle: Text((q['options'] as List?)?.join(' · ') ?? ''),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                      if (conceptMap.isNotEmpty) ...[
                        const Text('Concept Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(conceptMap.join(' → ')),
                        const SizedBox(height: 16),
                      ],
                      if (spaced.isNotEmpty) ...[
                        const Text('Spaced Repetition', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        for (final s in spaced) Text('• ${s.toString()}'),
                      ],
                    ],
                  ),
                ),
    );
  }
}
