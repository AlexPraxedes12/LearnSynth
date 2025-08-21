import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/flashcard_widget.dart';
import '../widgets/wide_button.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Presents flashcard‑style activities for memorization. Buttons for
/// grading difficulty are included. Completion navigates to the
/// progress screen via [Navigator.pushNamed].
class MemorizationScreen extends StatelessWidget {
  const MemorizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    final cards = p.studyPack == null ? const [] : p.safeList(p.studyPack!, 'flashcards');
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
                    final c = (cards[index] as Map?) ?? {};
                    return FlashcardWidget(
                      question: c['question']?.toString() ?? c['term']?.toString() ?? '',
                      answer:
                          c['answer']?.toString() ?? c['definition']?.toString() ?? '',
                    );
                  },
                ),
              )
            else
              const Text('No flashcards generated'),
            const SizedBox(height: 16),
            WideButton(
              label: 'Complete Session',
              onPressed: () => Navigator.pushNamed(context, Routes.progress),
            ),
          ],
        ),
      ),
    );
  }
}
