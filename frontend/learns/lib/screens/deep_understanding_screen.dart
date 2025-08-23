import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';

class DeepUnderstandingScreen extends StatelessWidget {
  const DeepUnderstandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prompts = context.watch<ContentProvider>().deepPrompts;

    return Scaffold(
      appBar: AppBar(title: const Text('Deep Understanding')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                prompts[i],
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        },
      ),
    );
  }
}
