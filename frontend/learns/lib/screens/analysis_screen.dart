import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentProvider>(
      builder: (context, p, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Study Pack')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: () {
              if (p.analyzing) {
                return const Center(child: CircularProgressIndicator());
              }
              if (p.error != null) {
                return Text(p.error!, style: const TextStyle(color: Colors.red));
              }
              final pack = p.studyPack;
              if (pack == null) {
                return const Text('No analysis yet. Transcribe and continue to generate the pack.');
              }

              // Safely read common sections:
              final summary = (pack['summary'] ?? '').toString();
              final items   = (pack['items'] is List) ? (pack['items'] as List) : const [];
              final flash    = (pack['flashcards'] is List) ? (pack['flashcards'] as List) : const [];
              final quiz     = (pack['quiz'] is List) ? (pack['quiz'] as List) : const [];

              return ListView(
                children: [
                  if (summary.isNotEmpty) ...[
                    const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(summary),
                    const SizedBox(height: 16),
                  ],
                  if (items.isNotEmpty) ...[
                    const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...items.map((e) => Text(e.toString())),
                    const SizedBox(height: 16),
                  ],
                  if (flash.isNotEmpty) ...[
                    const Text('Flashcards', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...flash.map((e) => Text(e.toString())),
                    const SizedBox(height: 16),
                  ],
                  if (quiz.isNotEmpty) ...[
                    const Text('Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...quiz.map((e) => Text(e.toString())),
                  ],
                ],
              );
            }(),
          ),
        );
      },
    );
  }
}
