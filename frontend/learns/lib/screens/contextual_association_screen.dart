import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';

class ContextualAssociationScreen extends StatelessWidget {
  const ContextualAssociationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = context.watch<ContentProvider>().conceptTopics;

    return Scaffold(
      appBar: AppBar(title: const Text('Concept Map')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final t in topics)
              Chip(
                label: Text(t),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
          ],
        ),
      ),
    );
  }
}

