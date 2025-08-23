import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';

/// Shows one reflective prompt at a time to encourage deeper thinking.
/// Answers are stored locally and can be persisted later if needed.
class DeepUnderstandingScreen extends StatefulWidget {
  const DeepUnderstandingScreen({super.key});

  @override
  State<DeepUnderstandingScreen> createState() => _DeepUnderstandingScreenState();
}

class _DeepUnderstandingScreenState extends State<DeepUnderstandingScreen> {
  int _i = 0;
  final _controller = TextEditingController();
  // Optional: store answers locally; persist later if desired
  final Map<int, String> _answers = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    final prompts = p.deepPrompts;
    if (prompts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deep Understanding')),
        body: const Center(child: Text('No prompts available.')),
      );
    }

    _controller.value = TextEditingValue(text: _answers[_i] ?? '');

    return Scaffold(
      appBar: AppBar(title: const Text('Deep Understanding')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prompt ${_i + 1} of ${prompts.length}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(prompts[_i],
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Write your reflection here…',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _answers[_i] = v,
            ),
            const Spacer(),
            Row(
              children: [
                TextButton(
                  onPressed: _i == 0 ? null : () => setState(() => _i--),
                  child: const Text('Prev'),
                ),
                const Spacer(),
                if (_i < prompts.length - 1)
                  ElevatedButton(
                    onPressed: () => setState(() => _i++),
                    child: const Text('Next'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      // Optional: save answers somewhere; for now just mark done.
                      context.read<ContentProvider>().markDeepDone();
                      Navigator.pop(context);
                    },
                    child: const Text('Done'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
