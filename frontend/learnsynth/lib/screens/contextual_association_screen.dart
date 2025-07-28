import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';

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
            Text(
              'Main content text goes here',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text('📚'),
            SizedBox(height: 16),
            Text('Learning Flutter is like assembling building blocks.'),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Complete Session',
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, Routes.progress),
            )
          ],
        ),
      ),
    );
  }
}
