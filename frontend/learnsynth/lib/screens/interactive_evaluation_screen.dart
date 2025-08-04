import 'package:flutter/material.dart';
import '../widgets/quiz_question_card.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Presents an interactive quiz. After submitting answers, the user can
/// complete the session which navigates to the progress screen using
/// [Navigator.pushNamed].
class InteractiveEvaluationScreen extends StatefulWidget {
  const InteractiveEvaluationScreen({super.key});

  @override
  State<InteractiveEvaluationScreen> createState() =>
      _InteractiveEvaluationScreenState();
}

class _InteractiveEvaluationScreenState
    extends State<InteractiveEvaluationScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    if (provider.evaluationQuestions.isNotEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final url = Uri.parse('http://10.0.2.2:8000/analyze');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'text': provider.content, 'mode': 'interactive_evaluation'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final questions =
            (data['evaluationQuestions'] as List? ?? [])
                .map<Map<String, dynamic>>(
                    (e) => Map<String, dynamic>.from(e as Map))
                .toList();
        provider.setEvaluationQuestions(questions);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load questions')),
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
    final exercises = context.watch<ContentProvider>().evaluationQuestions;
    return Scaffold(
      appBar: AppBar(title: const Text('Interactive Evaluation')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (exercises.isNotEmpty)
                    Expanded(
                      child: ListView.separated(
                        itemCount: exercises.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final ex = exercises[index];
                          if (ex.containsKey('choices')) {
                            return QuizQuestionCard(
                              question: ex['question'] ?? '',
                              choices:
                                  List<String>.from(ex['choices'] ?? const []),
                              correctIndex: ex['correctIndex'] as int? ?? 0,
                            );
                          }
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(ex['question']?.toString() ?? ex.toString()),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const Text('No questions generated'),
                  const SizedBox(height: 16),
                  PrimaryButton(label: 'Submit', onPressed: () {}),
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