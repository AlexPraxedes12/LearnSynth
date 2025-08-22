import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';

class InteractiveEvaluationScreen extends StatefulWidget {
  const InteractiveEvaluationScreen({super.key});
  @override
  State<InteractiveEvaluationScreen> createState() =>
      _InteractiveEvaluationScreenState();
}

class _InteractiveEvaluationScreenState
    extends State<InteractiveEvaluationScreen> {
  int i = 0;
  int score = 0;
  int? selected;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    final quiz = p.quiz;
    final q = (quiz.isEmpty) ? null : quiz[i];

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: (q == null)
          ? const Center(child: Text('No questions available'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q${i + 1}. ${q.question}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...List.generate(q.options.length, (idx) {
                    final opt = q.options[idx];
                    return RadioListTile<int>(
                      value: idx,
                      groupValue: selected,
                      onChanged: (v) => setState(() => selected = v),
                      title: Text(opt),
                    );
                  }),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: selected == null
                        ? null
                        : () {
                            if (selected == q.answer) score++;
                            if (i < quiz.length - 1) {
                              setState(() {
                                i++;
                                selected = null;
                              });
                            } else {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Result'),
                                  content:
                                      Text('Score: $score/${quiz.length}'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text('OK'),
                                    )
                                  ],
                                ),
                              );
                            }
                          },
                    child:
                        Text(i < quiz.length - 1 ? 'Next' : 'Finish'),
                  ),
                ],
              ),
            ),
    );
  }
}

