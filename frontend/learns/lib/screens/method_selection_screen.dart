import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../widgets/wide_button.dart';

class MethodSelectionScreen extends StatefulWidget {
  const MethodSelectionScreen({super.key});

  @override
  State<MethodSelectionScreen> createState() => _MethodSelectionScreenState();
}

class _MethodSelectionScreenState extends State<MethodSelectionScreen> {
  late final ContentProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ContentProvider>();
  }

  @override
  void dispose() {
    // Reset provider after the widget is fully disposed to avoid triggering
    // notifications while the widget tree is locked.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.resetAll();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Study Pack')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(p.summary ?? ''),
            const SizedBox(height: 16),
            WideButton(
              label: 'Memorization (Flashcards)',
              enabled: p.flashcards.isNotEmpty,
              onPressed: p.flashcards.isNotEmpty
                  ? () => Navigator.pushNamed(context, Routes.memorization)
                  : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: 'Deep Understanding',
              enabled: p.canDeepUnderstanding,
              onPressed: p.canDeepUnderstanding
                  ? () => Navigator.pushNamed(context, Routes.deep)
                  : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: 'Contextual Association',
              enabled: p.canContextualAssociation,
              onPressed: p.canContextualAssociation
                  ? () => Navigator.pushNamed(context, Routes.concept)
                  : null,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: 'Interactive Evaluation (Quiz)',
              enabled: p.quizzes.isNotEmpty,
              onPressed: p.quizzes.isNotEmpty
                  ? () => Navigator.pushNamed(context, Routes.quiz)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
