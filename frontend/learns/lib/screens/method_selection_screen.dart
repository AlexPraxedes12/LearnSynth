import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../widgets/wide_button.dart';

class MethodSelectionScreen extends StatelessWidget {
  const MethodSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();

    final enableFlash = p.hasMemorization;
    final enableDeep = p.hasDeepUnderstanding;
    final enableConcept = p.hasContextualAssociation;
    final enableQuiz = p.hasQuiz;

    return Scaffold(
      appBar: AppBar(title: const Text('Study Pack')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(p.summary ?? ''),

          const SizedBox(height: 24),

          WideButton(
            label: 'Memorization (Flashcards)',
            enabled: enableFlash,
            onPressed: enableFlash
                ? () => Navigator.pushNamed(context, Routes.memorization)
                : null,
          ),
          const SizedBox(height: 12),

          WideButton(
            label: 'Deep Understanding',
            enabled: enableDeep,
            onPressed: enableDeep
                ? () => Navigator.pushNamed(context, Routes.deepUnderstanding)
                : null,
          ),
          const SizedBox(height: 12),

          WideButton(
            label: 'Contextual Association',
            enabled: enableConcept,
            onPressed: enableConcept
                ? () => Navigator.pushNamed(context, Routes.contextualAssociation)
                : null,
          ),
          const SizedBox(height: 12),

          WideButton(
            label: 'Interactive Evaluation (Quiz)',
            enabled: enableQuiz,
            onPressed: enableQuiz
                ? () => Navigator.pushNamed(context, Routes.interactiveEvaluation)
                : null,
          ),
        ],
      ),
    );
  }
}
