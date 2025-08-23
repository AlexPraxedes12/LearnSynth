import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../widgets/wide_button.dart';

/// Shows one reflective prompt at a time to encourage deeper thinking.
class DeepUnderstandingScreen extends StatelessWidget {
  const DeepUnderstandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final prompts = provider.deepPrompts;

    if (prompts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deep Understanding')),
        body: const Center(child: Text('No deep prompts available.')),
      );
    }

    int index = 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Deep Understanding')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StatefulBuilder(
          builder: (context, setState) {
            final p = prompts[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.prompt,
                            style: Theme.of(context).textTheme.titleMedium),
                        if (p.hint.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(p.hint,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    WideButton(
                      label: 'Prev',
                      onPressed:
                          index > 0 ? () => setState(() => index--) : null,
                    ),
                    WideButton(
                      label: 'Next',
                      onPressed: index < prompts.length - 1
                          ? () => setState(() => index++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                WideButton(
                  label: 'Complete Session',
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.progress),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

