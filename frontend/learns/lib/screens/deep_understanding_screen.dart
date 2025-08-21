import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/wide_button.dart';
import '../constants.dart';
import '../content_provider.dart';
import '../widgets/key_value_card.dart';

/// Provides a deep understanding session. Users can listen to an
/// audio explanation and view a concept map. Upon completion, they
/// navigate to the progress screen using a named route (not

/// replacement) to preserve navigation history.
class DeepUnderstandingScreen extends StatelessWidget {
  const DeepUnderstandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final conceptMap = provider.conceptMap;
    final links = (conceptMap?['links'] as List?);

    return Scaffold(
      appBar: AppBar(title: const Text('Deep Understanding')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (links != null && links.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: links.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final link = links[index] as Map<String, dynamic>;
                    return KeyValueCard(data: link);
                  },
                ),
              )
            else
              const Center(child: Text('No concept map available.')),
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

