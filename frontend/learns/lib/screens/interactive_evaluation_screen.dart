import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';
import '../widgets/wide_button.dart';

class InteractiveEvaluationScreen extends StatefulWidget {
  const InteractiveEvaluationScreen({super.key});
  @override
  State<InteractiveEvaluationScreen> createState() => _InteractiveEvaluationScreenState();
}

class _InteractiveEvaluationScreenState extends State<InteractiveEvaluationScreen> {
  int i = 0, score = 0, selected = -1;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    final items = p.quizzes;
    final q = items[i];

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question ${i + 1} of ${items.length}', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(q.question, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            for (final idx in List.generate(q.options.length, (x) => x))
              RadioListTile<int>(
                value: idx,
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v!),
                title: Text(q.options[idx]),
              ),
            const Spacer(),
            WideButton(
              label: i == items.length - 1 ? 'Finish' : 'Next',
              enabled: selected != -1,
              onPressed: () {
                if (selected == q.answerIndex) score++;
                if (i == items.length - 1) {
                  p.saveQuizScore(score);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Results'),
                      content: Text('Score: $score / ${items.length}'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst || r.settings.name == '/studyPack'),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                } else {
                  setState(() { i++; selected = -1; });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
