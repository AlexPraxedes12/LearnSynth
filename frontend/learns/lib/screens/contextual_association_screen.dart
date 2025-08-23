import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';

/// Displays concept relationships as groups or chips to help build mental models.
class ContextualAssociationScreen extends StatelessWidget {
  const ContextualAssociationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final groups = provider.conceptGroups;

    Widget buildChips(List<String> items) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((t) => Chip(label: Text(t))).toList(),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Concept Map')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: groups.isNotEmpty
            ? ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, i) {
                  final g = groups[i];
                  return ExpansionTile(
                    title: Text(g.title),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: buildChips(g.topics),
                      )
                    ],
                  );
                },
              )
            : Center(
                child: buildChips(
                  provider.conceptGroups.expand((g) => g.topics).toList(),
                ),
              ),
      ),
    );
  }
}
