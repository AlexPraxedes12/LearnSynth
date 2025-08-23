import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content_provider.dart';

/// Displays concept relationships as groups or chips to help build mental models.
class ContextualAssociationScreen extends StatelessWidget {
  const ContextualAssociationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    final groups = p.conceptGroups;
    final topics = p.conceptTopics;

    final palette = [
      Colors.teal,
      Colors.indigo,
      Colors.deepOrange,
      Colors.purple,
      Colors.blueGrey,
      Colors.brown,
      Colors.green,
      Colors.cyan,
    ];

    Widget chip(String t, Color c) {
      return GestureDetector(
        onLongPress: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(t)));
        },
        child: ActionChip(
          label: Text(
            t,
            style: TextStyle(color: c, fontWeight: FontWeight.bold),
          ),
          backgroundColor: c.withOpacity(0.2),
          onPressed: () {},
        ),
      );
    }

    if (p.hasConceptGroups) {
      return Scaffold(
        appBar: AppBar(title: const Text('Concept Map')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: groups.asMap().entries.map((entry) {
                final color = palette[entry.key % palette.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(entry.value.title),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            ...groups.asMap().entries.map((entry) {
              final idx = entry.key;
              final group = entry.value;
              final color = palette[idx % palette.length];
              return ExpansionTile(
                title: Text(group.title),
                initiallyExpanded: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          group.topics.map((t) => chip(t, color)).toList(),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      );
    } else if (topics.isNotEmpty) {
      final color = palette.first;
      return Scaffold(
        appBar: AppBar(title: const Text('Concept Map')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ExpansionTile(
              title: const Text('Topics'),
              initiallyExpanded: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: topics.map((t) => chip(t, color)).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('Concept Map')),
        body: const Center(child: Text('No concept topics available.')),
      );
    }
  }
}

