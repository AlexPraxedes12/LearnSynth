import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';
import '../widgets/wide_button.dart';

class DeepUnderstandingScreen extends StatefulWidget {
  const DeepUnderstandingScreen({super.key});
  @override
  State<DeepUnderstandingScreen> createState() => _DeepUnderstandingScreenState();
}

class _DeepUnderstandingScreenState extends State<DeepUnderstandingScreen> {
  final _notes = <String, String>{};

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Deep Understanding')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (p.deepPrompts.isEmpty)
            const Text('No reflective prompts available.'),
          for (final q in p.deepPrompts) ...[
            Text(q, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              minLines: 2, maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Your reflection...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _notes[q] = v,
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 12),
          WideButton(
            label: 'Mark as done',
            enabled: p.deepPrompts.isNotEmpty,
            onPressed: () {
              p.markDeepDone();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
