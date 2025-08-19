import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/flashcard_widget.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Presents flashcard‑style activities for memorization. Buttons for
/// grading difficulty are included. Completion navigates to the
/// progress screen via [Navigator.pushNamed].
class MemorizationScreen extends StatelessWidget {
  const MemorizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<ContentProvider>().flashcards;
    return Scaffold(
      appBar: AppBar(title: const Text('Memorization')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (cards.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: cards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final c = cards[index];
                    return FlashcardWidget(
                      question: c['question'] ?? '',
                      answer: c['answer'] ?? '',
                    );
                  },
                ),
              )
            else
              const Text('No flashcards generated'),
            const SizedBox(height: 16),
            PrimaryButton(
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

