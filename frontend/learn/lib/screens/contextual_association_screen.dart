import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';
import '../widgets/key_value_card.dart';

/// Encourages users to relate concepts to real‑world scenarios. Once
/// complete, navigation continues to the progress screen using
/// [Navigator.pushNamed].
class ContextualAssociationScreen extends ConsumerWidget {
  const ContextualAssociationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(contentProvider).contextualExercises;
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
                    return KeyValueCard(data: ex);
                  },
                ),
              )
            else
              const Center(child: Text('No exercises generated.')),
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

