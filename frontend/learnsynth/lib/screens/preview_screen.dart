import 'package:flutter/material.dart';

import '../widgets/primary_button.dart';
import '../constants.dart';

/// Displays the provided text in a scrollable container and allows
/// the user to start the analysis process.
class PreviewScreen extends StatelessWidget {
  final String text;
  const PreviewScreen({super.key, required this.text});

  void _startAnalysis(BuildContext context) {
    Navigator.pushNamed(
      context,
      Routes.processing,
      arguments: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white70),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Start Analysis',
              onPressed: () => _startAnalysis(context),
            ),
          ],
        ),
      ),
    );
  }
}

