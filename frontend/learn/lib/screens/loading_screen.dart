import 'package:flutter/material.dart';
import '../widgets/quote_card.dart';
import '../constants.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Shows a loading state while content is being processed. Once the
/// processing is complete, the user can proceed to the analysis
/// screen. We use [Navigator.pushNamed] here rather than
/// [Navigator.pushReplacementNamed] so that the user can navigate
/// back if desired.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ContentProvider>(context, listen: false);
    if (provider.summary != null && provider.summary!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.pushNamed(context, Routes.analysis),
      );
    } else {
      _analyze();
    }
  }

  Future<void> _analyze() async {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    try {
      final url = Uri.parse('http://10.0.2.2:8000/analyze');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': provider.rawText ?? provider.content}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        provider.setAnalysis(
          data['summary'] as String? ?? '',
          List<String>.from(data['topics'] as List? ?? []),
        );
        provider.setFlashcards(
          (data['flashcards'] as List? ?? [])
              .map<Map<String, String>>(
                  (e) => Map<String, String>.from(e as Map))
              .toList(),
        );
        final conceptMap = data['concept_map'] as Map?;
        if (conceptMap != null) {
          provider.setConceptMap(Map<String, dynamic>.from(conceptMap));
        }
        provider.setContextualExercises(
          (data['contextual_exercises'] as List? ?? [])
              .map<Map<String, dynamic>>(
                  (e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
        provider.setEvaluationQuestions(
          ((data['quiz'] ?? data['evaluation_questions']) as List? ?? [])
              .map<Map<String, dynamic>>(
                  (e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
        provider.setActivitySummaries(
          Map<String, String>.from(data['activities'] as Map? ?? {}),
        );
        provider.setProgress(
          Map<String, dynamic>.from(data['progress'] as Map? ?? {}),
        );
        if (mounted) {
          Navigator.pushNamed(context, Routes.analysis);
        }
      } else {
        var message = 'Analysis failed';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
            message = decoded['detail'].toString();
          } else {
            message = decoded.toString();
          }
        } catch (_) {
          if (response.body.isNotEmpty) message = response.body;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            QuoteCard(quote: 'Learning never exhausts the mind.'),
          ],
        ),
      ),
    );
  }
}
