import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';

class MemorizationScreen extends StatefulWidget {
  const MemorizationScreen({super.key});
  @override
  State<MemorizationScreen> createState() => _MemorizationScreenState();
}

class _MemorizationScreenState extends State<MemorizationScreen> {
  int i = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    final cards = p.flashcards;
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: cards.isEmpty
          ? const Center(child: Text('No flashcards available'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Term: ${cards[i].term}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Text('Definition: ${cards[i].definition}'),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: i > 0 ? () => setState(() => i--) : null,
                          child: const Text('Prev'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: i < cards.length - 1
                              ? () => setState(() => i++)
                              : null,
                          child: const Text('Next'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

