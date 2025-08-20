import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/method_card.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Lists the available study methods. Each card navigates to its
/// corresponding screen using a named route.
class MethodSelectionScreen extends ConsumerWidget {
  const MethodSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(contentProvider).activitySummaries;
    return Scaffold(
      appBar: AppBar(title: const Text('Study Methods')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            MethodCard(
              icon: Icons.lightbulb_outline,
              title: 'Deep Understanding',
              description: 'Listen to explanations and see concept maps.',
              summary: summaries['deep_understanding'],
              onTap: () =>
                  Navigator.pushNamed(context, Routes.deepUnderstanding),
            ),
            MethodCard(
              icon: Icons.memory,
              title: 'Memorization',
              description: 'Use flashcards to remember key points.',
              summary: summaries['memorization'],
              onTap: () => Navigator.pushNamed(context, Routes.memorization),
            ),
            MethodCard(
              icon: Icons.share,
              title: 'Contextual Association',
              description: 'Relate concepts to real-life scenarios.',
              summary: summaries['contextual_association'],
              onTap: () =>
                  Navigator.pushNamed(context, Routes.contextualAssociation),
            ),
            MethodCard(
              icon: Icons.quiz,
              title: 'Interactive Evaluation',
              description: 'Answer quiz questions to test knowledge.',
              summary: summaries['interactive_evaluation'],
              onTap: () =>
                  Navigator.pushNamed(context, Routes.interactiveEvaluation),
            ),
          ],
        ),
      ),
    );
  }
}

