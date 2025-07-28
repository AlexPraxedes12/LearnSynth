import 'package:flutter/material.dart';
import '../widgets/quote_card.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';

/// Shows a loading state while content is being processed. Once the
/// processing is complete, the user can proceed to the analysis
/// screen. We use [Navigator.pushNamed] here rather than
/// [Navigator.pushReplacementNamed] so that the user can navigate
/// back if desired.
class ProcessingScreen extends StatelessWidget {
  const ProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Processing')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const QuoteCard(quote: 'Learning never exhausts the mind.'),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'View Analysis',
              onPressed: () => Navigator.pushNamed(context, Routes.analysis),
            ),
          ],
        ),
      ),
    );
  }
}