import 'package:flutter/material.dart';

/// A small card summarising a key progress metric. Adapted from
/// upstream. Displays a title and a value side‑by‑side.
class ProgressSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  const ProgressSummaryCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}