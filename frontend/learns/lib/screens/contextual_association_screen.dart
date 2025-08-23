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

    return Scaffold(
      appBar: AppBar(title: const Text('Concept Map')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: groups.isNotEmpty
            ? ListView(
                children: groups.entries.map((e) {
                  final title = e.key;
                  final children = e.value;
                  return Card(
                    child: ExpansionTile(
                      title: Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      children: [
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: children
                                .map((t) => Padding(
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 6),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('• '),
                                          Expanded(child: Text(t)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            : (topics.isNotEmpty
                ? SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: topics
                          .map((t) => Chip(
                                label: Text(t),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  )
                : const Center(child: Text('No concepts available.'))),
      ),
    );
  }
}
