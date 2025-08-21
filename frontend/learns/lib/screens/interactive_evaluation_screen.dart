import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/quiz_question_card.dart';
import '../widgets/wide_button.dart';
import '../constants.dart';
import '../content_provider.dart';
import '../widgets/key_value_card.dart';

/// Presents an interactive quiz. After submitting answers, the user can
/// complete the session which navigates to the progress screen using
/// [Navigator.pushNamed].
class InteractiveEvaluationScreen extends StatelessWidget {
  const InteractiveEvaluationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pack = context.watch<ContentProvider>().studyPack;
    final exercises = (pack?['quiz'] is List)
        ? List<Map<String, dynamic>>.from(pack!['quiz'])
        : const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Interactive Evaluation')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (exercises.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: exercises.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final ex = exercises[index];
                    if (ex.containsKey('choices')) {
                      return QuizQuestionCard(
                        question: ex['question'] ?? '',
                        choices: List<String>.from(ex['choices'] ?? const []),
                        correctIndex: ex['correctIndex'] as int? ?? 0,
                      );
                    }
                    return KeyValueCard(data: ex);
                  },
                ),
              )
            else
              const Center(child: Text('No questions generated.')),
            const SizedBox(height: 16),
            WideButton(
              label: 'Submit',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not implemented')),
                );
              },
            ),
            const SizedBox(height: 16),
            WideButton(
              label: 'Complete Session',
              onPressed: () =>
                  Navigator.pushNamed(context, Routes.progress),
            ),
          ],
        ),
      ),
    );
  }
}

