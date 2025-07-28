import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';

/// Encourages users to relate concepts to real‑world scenarios. Once
/// complete, navigation continues to the progress screen using
/// [Navigator.pushNamed].
class ContextualAssociationScreen extends StatelessWidget {
  const ContextualAssociationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contextual Association')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Main content text goes here',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('📚'),
            const SizedBox(height: 16),
            const Text('Learning Flutter is like assembling building blocks.'),
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