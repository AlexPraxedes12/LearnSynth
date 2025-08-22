import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';
import '../widgets/wide_button.dart';
import 'memorization_screen.dart';
import 'deep_understanding_screen.dart';
import 'contextual_association_screen.dart';
import 'interactive_evaluation_screen.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Study Pack')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (p.hasSummary) ...[
              const Text('Summary', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(p.summary),
              const SizedBox(height: 24),
            ],
            WideButton(
              label: 'Memorization (Flashcards)',
              onPressed: p.hasFlashcards
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MemorizationScreen()),
                      )
                  : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: 'Deep Understanding',
              onPressed: p.hasDeepPrompts
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DeepUnderstandingScreen()),
                      )
                  : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: 'Contextual Association',
              onPressed: p.hasConceptMap
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ContextualAssociationScreen()),
                      )
                  : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: 'Interactive Evaluation (Quiz)',
              onPressed: p.hasQuiz
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const InteractiveEvaluationScreen()),
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

