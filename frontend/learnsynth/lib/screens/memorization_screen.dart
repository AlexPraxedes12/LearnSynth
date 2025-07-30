import 'package:flutter/material.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Presents flashcard‑style activities for memorization. Buttons for
/// grading difficulty are included. Completion navigates to the
/// progress screen via [Navigator.pushNamed].
class MemorizationScreen extends StatefulWidget {
  const MemorizationScreen({super.key});

  @override
  State<MemorizationScreen> createState() => _MemorizationScreenState();
}

class _MemorizationScreenState extends State<MemorizationScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    if (provider.flashcards.isNotEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final url = Uri.parse('http://10.0.2.2:8000/study-mode');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': provider.text, 'mode': 'memorization'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final cards = (data['flashcards'] as List? ?? data['cards'] as List? ?? [])
            .map<Map<String, String>>(
                (e) => Map<String, String>.from(e as Map))
            .toList();
        provider.setFlashcards(cards);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load flashcards')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error')),
      );
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final cards = provider.flashcards;
    return Scaffold(
      appBar: AppBar(title: const Text('Memorization')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (cards.isNotEmpty)
                    Expanded(
                      child: ListView.separated(
                        itemCount: cards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final c = cards[index];
                          return FlashcardWidget(
                            question: c['question'] ?? '',
                            answer: c['answer'] ?? '',
                          );
                        },
                      ),
                    )
                  else
                    const Text('No flashcards generated'),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Complete Session',
                    onPressed: () =>
                        Navigator.pushNamed(context, Routes.progress),
                  ),
                ],
              ),
      ),
    );
  }
}