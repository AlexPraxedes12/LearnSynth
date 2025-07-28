import 'package:flutter/material.dart';
import '../widgets/quiz_question_card.dart';
import '../widgets/primary_button.dart';

class InteractiveEvaluationScreen extends StatelessWidget {
  const InteractiveEvaluationScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
    );
  }
}
