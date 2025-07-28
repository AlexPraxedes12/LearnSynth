import 'package:flutter/material.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';

/// Presents flashcard‑style activities for memorization. Buttons for
/// grading difficulty are included. Completion navigates to the
/// progress screen via [Navigator.pushNamed].
class MemorizationScreen extends StatelessWidget {
  const MemorizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memorization')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const FlashcardWidget(
              question: 'What is Flutter?',
              answer: 'An open-source UI toolkit by Google.',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Easy')),
                ElevatedButton(onPressed: () {}, child: const Text('Hard')),
                ElevatedButton(onPressed: () {}, child: const Text('Repeat')),
              ],
            ),
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