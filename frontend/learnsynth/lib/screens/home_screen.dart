import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Content')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrimaryButton(
                  label: 'Paste Text',
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.processing),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Upload PDF',
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.processing),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Record Audio',
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.processing),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Upload Video',
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.processing),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
