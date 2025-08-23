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
    final topics = p.flatConceptTopics;
    return Scaffold(
      appBar: AppBar(title: const Text('Concept Map')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: groups.isNotEmpty
            ? ListView(
                children: groups.length == 1
                    // Single group: render just chips without a collapsible header
                    ? [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                              groups.first.topics.map((t) => _chip(t)).toList(),
                        )
                      ]
                    // Multiple groups: ExpansionTiles
                    : groups
                        .map((g) => ExpansionTile(
                              title: Text(g.title),
                              initiallyExpanded: true,
                              children: [
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children:
                                      g.topics.map((t) => _chip(t)).toList(),
                                ),
                                const SizedBox(height: 8),
                                const Divider(),
                              ],
                            ))
                        .toList(),
              )
            : topics.isNotEmpty
                ? Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: topics.map((t) => _chip(t)).toList(),
                  )
                : const Center(child: Text('No concept topics available.')),
      ),
    );
  }
}

Widget _chip(String t) {
  return ActionChip(
    label: Text(t),
    onPressed: () {
      // Optional: later you can show a small dialog with a 1-line definition if backend adds it.
    },
  );
}
