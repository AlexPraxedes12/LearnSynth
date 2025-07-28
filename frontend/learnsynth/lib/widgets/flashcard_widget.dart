import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A simple flashcard widget that toggles between showing the question
/// and the answer when tapped. Adapted from the upstream repository.
class FlashcardWidget extends StatefulWidget {
  final String question;
  final String answer;
  const FlashcardWidget({super.key, required this.question, required this.answer});

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget> {
  bool _showAnswer = false;

  void _toggle() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.accentGray,
      child: InkWell(
        onTap: _toggle,
        child: SizedBox(
          height: 200,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _showAnswer ? widget.answer : widget.question,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}