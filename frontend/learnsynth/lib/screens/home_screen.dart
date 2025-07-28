import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';

/// Initial landing page with quick navigation buttons.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PrimaryButton(
              label: 'Add Content',
              onPressed: () => Navigator.pushNamed(context, Routes.addContent),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Projects',
              onPressed: () => Navigator.pushNamed(context, Routes.projects),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Library',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
