import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';

/// Provides a deep understanding session. Users can listen to an
/// audio explanation and view a concept map. Upon completion, they
/// navigate to the progress screen using a named route (not
/// replacement) to preserve navigation history.
class DeepUnderstandingScreen extends StatelessWidget {
  const DeepUnderstandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deep Understanding')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Summary of the topic.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Analogy: Learning is like building a house.'),
            const SizedBox(height: 16),
            Container(
              height: 150,
              color: Colors.black26,
              child: const Center(child: Text('Concept Map Preview')),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Play Audio Explanation',
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Complete Session',
              onPressed: () => Navigator.pushNamed(context, Routes.progress),
            ),
          ],
        ),
      ),
    );
  }
}