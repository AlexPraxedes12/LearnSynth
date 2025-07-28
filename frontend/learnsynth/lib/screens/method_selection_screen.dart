import 'package:flutter/material.dart';
import '../widgets/method_card.dart';
import '../constants.dart';

class MethodSelectionScreen extends StatelessWidget {
  const MethodSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              onTap: () =>
                  Navigator.pushNamed(context, Routes.deepUnderstanding),
            ),
            MethodCard(
              icon: Icons.memory,
              title: 'Memorization',
              description: 'Use flashcards to remember key points.',
              onTap: () => Navigator.pushNamed(context, Routes.memorization),
            ),
            MethodCard(
              icon: Icons.share,
              title: 'Contextual Association',
              description: 'Relate concepts to real-life scenarios.',
              onTap: () =>
                  Navigator.pushNamed(context, Routes.contextualAssociation),
            ),
            MethodCard(
              icon: Icons.quiz,
              title: 'Interactive Evaluation',
              description: 'Answer quiz questions to test knowledge.',
              onTap: () =>
                  Navigator.pushNamed(context, Routes.interactiveEvaluation),
            ),
          ],
        ),
      ),
    );
  }
}
