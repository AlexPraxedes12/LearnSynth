import 'package:flutter/material.dart';
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
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            QuoteCard(quote: 'Progress tracking not implemented'),
          ],
        ),
      ),
    );
  }
}