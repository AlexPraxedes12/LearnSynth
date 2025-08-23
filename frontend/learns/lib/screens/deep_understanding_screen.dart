import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content_provider.dart';

/// Shows one reflective prompt at a time to encourage deeper thinking.
class DeepUnderstandingScreen extends StatelessWidget {
  const DeepUnderstandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    final items = p.deepPrompts;
    if (items.isEmpty) {
      // Defensive: if someone lands here without data
      return Scaffold(
        appBar: AppBar(title: const Text('Deep Understanding')),
        body: const Center(
            child: Text('No deep prompts available for this content.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Deep Understanding')),
      body: PageView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          final it = items[i];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(it.prompt,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                if (it.hint.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(it.hint,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFFAAAAAA))),
                ],
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text('${i + 1} / ${items.length}',
                      style:
                          const TextStyle(color: Color(0xFFAAAAAA))),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

