import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Encourages users to relate concepts to real‑world scenarios. Once
/// complete, navigation continues to the progress screen using
/// [Navigator.pushNamed].
class ContextualAssociationScreen extends StatefulWidget {
  const ContextualAssociationScreen({super.key});

  @override
  State<ContextualAssociationScreen> createState() =>
      _ContextualAssociationScreenState();
}

class _ContextualAssociationScreenState
    extends State<ContextualAssociationScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    if (provider.contextualExercises.isNotEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final url = Uri.parse('http://10.0.2.2:8000/study-mode');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': provider.text, 'mode': 'contextual_association'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final ex = (data['contextualExercises'] as List? ?? data['exercises'] as List? ?? [])
            .map<Map<String, dynamic>>( (e) => Map<String, dynamic>.from(e as Map))
            .toList();
        provider.setContextualExercises(ex);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load exercises')),
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
    final exercises = context.watch<ContentProvider>().contextualExercises;
    return Scaffold(
      appBar: AppBar(title: const Text('Contextual Association')),
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
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(ex['question']?.toString() ?? ex['prompt']?.toString() ?? ex.toString()),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const Text('No exercises generated'),
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