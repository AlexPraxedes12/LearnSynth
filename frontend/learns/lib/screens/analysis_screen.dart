import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';
import '../constants.dart';
import '../widgets/wide_button.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    final canDeep = p.hasDeep;
    final canConcept = p.canConcept;
    return Scaffold(
      appBar: AppBar(title: const Text('Study Pack')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (p.summary?.isNotEmpty ?? false) ...[
              const Text('Summary', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(p.summary!),
              const SizedBox(height: 24),
            ],
            WideButton(
              label: 'Memorization (Flashcards)',
              enabled: p.flashcards.isNotEmpty,
              onPressed: p.flashcards.isEmpty
                  ? null
                  : () => Navigator.pushNamed(context, Routes.memorization),
            ),
            const SizedBox(height: 12),
            WideButton(
              label: 'Deep Understanding',
              enabled: canDeep,
              onPressed:
                  canDeep ? () => Navigator.pushNamed(context, Routes.deep) : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: 'Contextual Association',
              enabled: canConcept,
              onPressed: canConcept
                  ? () => Navigator.pushNamed(context, Routes.concept)
                  : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: 'Interactive Evaluation (Quiz)',
              enabled: p.quizzes.isNotEmpty,
              onPressed: p.quizzes.isNotEmpty
                  ? () => Navigator.pushNamed(context, Routes.quiz)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
