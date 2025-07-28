import 'package:flutter/material.dart';
import '../widgets/progress_summary_card.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';

/// Displays summary statistics for the user’s progress. The "Back to
/// Home" button now uses [Navigator.pushNamedAndRemoveUntil] to clear
/// the navigation stack and return to the home screen cleanly.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            PrimaryButton(
              label: 'Back to Home',
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.home,
                (route) => false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}