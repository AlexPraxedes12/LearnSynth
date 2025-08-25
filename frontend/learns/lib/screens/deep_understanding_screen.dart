import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content_provider.dart';

/// Presents reflective prompts one at a time with optional hints.
class DeepUnderstandingScreen extends StatefulWidget {
  const DeepUnderstandingScreen({super.key});

  @override
  State<DeepUnderstandingScreen> createState() => _DeepUnderstandingState();
}

class _DeepUnderstandingState extends State<DeepUnderstandingScreen> {
  late ContentProvider _provider;
  late int _index;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ContentProvider>();
    _index = _provider.deepIndex;
  }

  void _setIndex(int idx) {
    setState(() {
      _index = idx;
      _showHint = false;
    });
    _provider.setDeepIndex(idx);
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<ContentProvider>().deepPrompts;
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deep Understanding')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No deep prompts available.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              )
            ],
          ),
        ),
      );
    }

    _index = _index.clamp(0, items.length - 1);
    final current = items[_index];
    final last = _index == items.length - 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Deep Understanding')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              current.prompt,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (current.hint.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _showHint = !_showHint),
                child: Text(_showHint ? 'Hide hint' : 'Show hint'),
              ),
              if (_showHint)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    current.hint,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
            ],
            const Spacer(),
            Text('${_index + 1} / ${items.length}',
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _index > 0 ? () => _setIndex(_index - 1) : null,
                    child: const Text('Prev'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (last) {
                        context.read<ContentProvider>().markDeepDone();
                        Navigator.pop(context);
                      } else {
                        _setIndex(_index + 1);
                      }
                    },
                    child: Text(last ? 'Finish' : 'Next'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

