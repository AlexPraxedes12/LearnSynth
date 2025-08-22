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
      body: prompts.isEmpty
          ? const Center(child: Text('No prompts available'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prompts.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (_, i) => Text('• ${prompts[i]}'),
            ),
    );
  }
}

