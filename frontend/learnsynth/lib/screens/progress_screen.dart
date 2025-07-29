import 'package:flutter/material.dart';
import '../widgets/progress_summary_card.dart';
import '../widgets/quote_card.dart';
import '../constants.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';

/// Displays summary statistics for the user’s progress. Navigation back
/// to the home page is provided by the bottom navigation bar, so we
/// simply show a motivational quote instead of a button.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    // TODO: POST /review/{id} to fetch progress
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const ProgressSummaryCard(title: 'Completed Sessions', value: '5'),
            const SizedBox(height: 16),
            const ProgressSummaryCard(title: 'Study Time', value: '2h 30m'),
            const SizedBox(height: 16),
            const ProgressSummaryCard(title: 'Methods Used', value: '3'),
            const SizedBox(height: 16),
            // Navigation back to home is handled by the bottom nav bar.
            // We show a motivational quote instead of a button.
            const QuoteCard(quote: 'Keep up the great work!'),
          ],
        ),
      ),
    );
  }
}