import 'package:flutter/material.dart';

/// A card that displays a multiple‑choice question. Users can select
/// an answer by tapping radio buttons. The selected index is stored
/// internally. Based on the upstream implementation.
class QuizQuestionCard extends StatefulWidget {
  final String question;
  final List<String> choices;
  final int correctIndex;
  const QuizQuestionCard({
    super.key,
    required this.question,
    required this.choices,
    required this.correctIndex,
  });

  @override
  State<QuizQuestionCard> createState() => _QuizQuestionCardState();
}

class _QuizQuestionCardState extends State<QuizQuestionCard> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(widget.choices.length, (index) {
              return RadioListTile<int>(
                activeColor: scheme.primary,
                title: Text(widget.choices[index]),
                value: index,
                groupValue: _selected,
                onChanged: (val) => setState(() => _selected = val),
              );
            }),
          ],
        ),
      ),
    );
  }
}