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
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                ProgressSummaryCard(
                  title: 'Completed Sessions',
                  value: '${progress['completedSessions'] ?? 0}',
                ),
                const SizedBox(height: 16),
                ProgressSummaryCard(
                  title: 'Study Time',
                  value: progress['studyTime']?.toString() ?? '0m',
                ),
                const SizedBox(height: 16),
                ProgressSummaryCard(
                  title: 'Methods Used',
                  value: '${progress['methodsUsed'] ?? 0}',
                ),
                const SizedBox(height: 16),
                // Navigation back to home is handled by the bottom nav bar.
                // We show a motivational quote instead of a button.
                const QuoteCard(quote: 'Keep up the great work!'),
              ],
            ),
          );
        },
      ),
    );
  }
}