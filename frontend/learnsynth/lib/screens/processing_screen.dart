import 'package:flutter/material.dart';
import '../widgets/quote_card.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';

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
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, Routes.analysis),
            )
          ],
        ),
      ),
    );
  }
}
