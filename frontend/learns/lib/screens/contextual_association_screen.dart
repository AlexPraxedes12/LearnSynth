import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';

/// Displays concept relationships as groups or chips to help build mental models.
class ContextualAssociationScreen extends StatelessWidget {
  const ContextualAssociationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    if (p.conceptGroups.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Concept Map')),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: p.conceptGroups.length,
          itemBuilder: (_, i) {
            final g = p.conceptGroups[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text(g.title),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          g.topics.map((t) => Chip(label: Text(t))).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      // Fallback: flat topics
      return Scaffold(
        appBar: AppBar(title: const Text('Concept Map')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                p.conceptTopics.map((t) => Chip(label: Text(t))).toList(),
          ),
        ),
      );
    }
  }
}
