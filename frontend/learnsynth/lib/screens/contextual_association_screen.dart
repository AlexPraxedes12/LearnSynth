import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Encourages users to relate concepts to real‑world scenarios. Once
/// complete, navigation continues to the progress screen using
/// [Navigator.pushNamed].
class ContextualAssociationScreen extends StatelessWidget {
  const ContextualAssociationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exercises = context.watch<ContentProvider>().contextualExercises;
    return Scaffold(
      appBar: AppBar(title: const Text('Contextual Association')),
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
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                            ex['question']?.toString() ?? ex['prompt']?.toString() ?? ex.toString()),
                      ),
                    );
                  },
                ),
              )
            else
              const Text('No exercises generated'),
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

