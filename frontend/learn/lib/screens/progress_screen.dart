import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content_provider.dart';
import '../widgets/progress_summary_card.dart';
import '../widgets/quote_card.dart';

/// Displays summary statistics for the user’s progress. Navigation back
/// to the home page is provided by the bottom navigation bar, so we
/// simply show a motivational quote instead of a button.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: Consumer<ContentProvider>(
        builder: (context, provider, _) {
          final progress = provider.progress;
          if (progress.isEmpty) {
            return Center(
              child: Text(
                'Could not load progress',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.white70),
              ),
            );
          }
          final entries = progress.entries.toList();
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView.separated(
              itemCount: entries.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index == entries.length) {
                  return const QuoteCard(quote: 'Keep up the great work!');
                }
                final entry = entries[index];
                return ProgressSummaryCard(
                  title: entry.key,
                  value: entry.value.toString(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}