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
    final flat = p.conceptTopics;

    Widget chip(String t) => ActionChip(
          label: Text(t),
          onPressed: () {},
        );

    Widget buildGroups() => ListView(
          padding: const EdgeInsets.all(16),
          children: groups
              .map((g) => ExpansionTile(
                    title: Text(g.title),
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (g.topics?.map<Widget>(chip).toList() ?? const <Widget>[]),
                      ),
                    ],
                  ))
              .toList(),
        );

    Widget buildFlat() => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ExpansionTile(
              initiallyExpanded: true,
              title: const Text('Topics'),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: flat.map(chip).toList(),
                ),
              ],
            ),
          ],
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Concept Map')),
      body: groups.isNotEmpty
          ? buildGroups()
          : flat.isNotEmpty
              ? buildFlat()
              : const Center(child: Text('No concept map available')),
    );
  }
}

