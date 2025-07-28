import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';

/// Presents the processed text to the user and allows them to choose
/// their preferred study method. The text is scrollable and uses
/// the current theme’s text styles.
class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String processedText = List.filled(10, 'Processed text goes here...\n').join();
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  processedText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Choose Study Mode',
              onPressed: () => Navigator.pushNamed(context, Routes.methodSelection),
            ),
          ],
        ),
      ),
    );
  }
}