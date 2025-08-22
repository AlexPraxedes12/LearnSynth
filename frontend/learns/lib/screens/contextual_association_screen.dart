import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';

class ContextualAssociationScreen extends StatelessWidget {
  const ContextualAssociationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final terms = context.watch<ContentProvider>().conceptMap;
    return Scaffold(
      appBar: AppBar(title: const Text('Concept Map')),
      body: terms.isEmpty
          ? const Center(child: Text('No concepts available'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: terms.map((t) => Chip(label: Text(t))).toList(),
              ),
            ),
    );
  }
}

