import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Provides a deep understanding session. Users can listen to an
/// audio explanation and view a concept map. Upon completion, they
/// navigate to the progress screen using a named route (not
/// replacement) to preserve navigation history.
class DeepUnderstandingScreen extends StatelessWidget {
  const DeepUnderstandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final map = context.watch<ContentProvider>().conceptMap;
    return Scaffold(
      appBar: AppBar(title: const Text('Deep Understanding')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (map != null)
              ...List.generate(
                (map['links'] as List? ?? []).length,
                (i) {
                  final link = (map['links'] as List)[i] as Map<String, dynamic>;
                  final src = link['source'];
                  final tgt = link['target'];
                  final lbl = link['label'] ?? '';
                  return Text('$src --$lbl--> $tgt');
                },
              )
            else
              const Text('No concept map'),
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

