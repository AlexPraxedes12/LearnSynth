import 'package:flutter/material.dart';
import '../widgets/quiz_question_card.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';

/// Presents an interactive quiz. After submitting answers, the user can
/// complete the session which navigates to the progress screen using
/// [Navigator.pushNamed].
class InteractiveEvaluationScreen extends StatelessWidget {
  const InteractiveEvaluationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    // TODO: POST /study-mode with mode=interactive_evaluation
    return Scaffold(
      appBar: AppBar(title: const Text('Interactive Evaluation')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const QuizQuestionCard(
              question: 'Flutter is written in which language?',
              choices: ['Java', 'Dart', 'Kotlin', 'Swift'],
              correctIndex: 1,
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Submit', onPressed: () {}),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Complete Session',
              onPressed: () => Navigator.pushNamed(context, Routes.progress),
            ),
          ],
        ),
      ),
    );
  }
}