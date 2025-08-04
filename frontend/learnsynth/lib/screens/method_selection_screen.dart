import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/method_card.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Lists the available study methods. Each card navigates to its
/// corresponding screen using a named route.
class MethodSelectionScreen extends StatefulWidget {
  const MethodSelectionScreen({super.key});

  @override
  State<MethodSelectionScreen> createState() => _MethodSelectionScreenState();
}

class _MethodSelectionScreenState extends State<MethodSelectionScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    if (provider.activitySummaries.isNotEmpty) {
      setState(() => _loading = false);
      return;
    }
    final text = provider.content;
    if (text == null || text.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final url = Uri.parse('http://10.0.2.2:8000/analyze');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final summaries =
            Map<String, String>.from(data['activities'] as Map? ?? {});
        provider.setActivitySummaries(summaries);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load activities')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final summaries = context.watch<ContentProvider>().activitySummaries;
    return Scaffold(
      appBar: AppBar(title: const Text('Study Methods')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                children: [
                  MethodCard(
                    icon: Icons.lightbulb_outline,
                    title: 'Deep Understanding',
                    description:
                        'Listen to explanations and see concept maps.',
                    summary: summaries['deep_understanding'],
                    onTap: () =>
                        Navigator.pushNamed(context, Routes.deepUnderstanding),
                  ),
                  MethodCard(
                    icon: Icons.memory,
                    title: 'Memorization',
                    description: 'Use flashcards to remember key points.',
                    summary: summaries['memorization'],
                    onTap: () =>
                        Navigator.pushNamed(context, Routes.memorization),
                  ),
                  MethodCard(
                    icon: Icons.share,
                    title: 'Contextual Association',
                    description: 'Relate concepts to real-life scenarios.',
                    summary: summaries['contextual_association'],
                    onTap: () => Navigator.pushNamed(
                        context, Routes.contextualAssociation),
                  ),
                  MethodCard(
                    icon: Icons.quiz,
                    title: 'Interactive Evaluation',
                    description: 'Answer quiz questions to test knowledge.',
                    summary: summaries['interactive_evaluation'],
                    onTap: () => Navigator.pushNamed(
                        context, Routes.interactiveEvaluation),
                  ),
                ],
              ),
            ),
    );
  }
}
