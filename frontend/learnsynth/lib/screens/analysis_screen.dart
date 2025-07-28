import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'Processed text goes here...\n' * 10,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Choose Study Mode',
              onPressed: () =>
                  Navigator.pushNamed(context, Routes.methodSelection),
            )
          ],
        ),
      ),
    );
  }
}
