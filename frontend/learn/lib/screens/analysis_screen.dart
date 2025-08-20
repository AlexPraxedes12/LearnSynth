import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Presents the processed text to the user and allows them to choose
/// their preferred study method. The text is scrollable and uses
/// the current theme’s text styles.
class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(contentProvider);
    final summary = provider.summary ?? 'Summary will appear here.';
    final topics = provider.topics.isNotEmpty
        ? provider.topics.join(', ')
        : 'Topics will appear here.';
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 12),
                    Text('Topics: $topics'),
                  ],
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