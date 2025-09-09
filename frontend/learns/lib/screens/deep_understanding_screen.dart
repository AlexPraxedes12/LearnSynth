import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content_provider.dart';

class DeepUnderstandingScreen extends StatefulWidget {
  const DeepUnderstandingScreen({super.key});

  @override
  State<DeepUnderstandingScreen> createState() => _DeepUnderstandingScreenState();
}

class _DeepUnderstandingScreenState extends State<DeepUnderstandingScreen> {
  final _controller = TextEditingController();
  int _lastIndex = -1;
  bool _showHint = false;
  late final ContentProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ContentProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.startStudySession('deep');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _provider.endStudySession('deep');
    // Don't update progress during dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ContentProvider>();
    final prompts = cp.deepPrompts;
    final theme = Theme.of(context).textTheme;
    Widget body;
    if (prompts.isNotEmpty) {
      final idx = cp.deepIndex;
      final p = prompts[idx];
      final answered = cp.deepCompleted.length > idx && cp.deepCompleted[idx];
      if (_lastIndex != idx) {
        _lastIndex = idx;
        _showHint = false;
        if (cp.deepResponses.length > idx) {
          _controller.text = cp.deepResponses[idx];
        } else {
          _controller.clear();
        }
      }
      body = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.prompt, style: theme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 4,
              readOnly: answered,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Your response',
              ),
            ),
            const SizedBox(height: 16),
            if (_showHint && p.hint.isNotEmpty)
              Text(p.hint, style: theme.bodyMedium),
            const Spacer(),
            Row(
              children: [
                if (p.hint.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showHint = !_showHint;
                      });
                    },
                    child: Text(_showHint ? 'Hide Answer' : 'Show Answer'),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (!answered) {
                      cp.submitDeepResponse(_controller.text.trim());
                      final completed =
                          cp.deepCompleted.where((c) => c).length;
                      cp.updateMethodProgress(
                          'deep', completed / prompts.length);
                      setState(() {
                        _showHint = true;
                      });
                    } else {
                      _controller.clear();
                      _showHint = false;
                      cp.nextDeepPrompt();
                      final completed =
                          cp.deepCompleted.where((c) => c).length;
                      cp.updateMethodProgress(
                          'deep', completed / prompts.length);
                    }
                  },
                  child: Text(answered ? 'Next' : 'Submit'),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No prompts available.', style: theme.bodyLarge),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Deep Understanding')),
      body: SafeArea(child: body),
    );
  }
}
