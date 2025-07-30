import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import 'package:provider/provider.dart';
import '../content_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Provides a deep understanding session. Users can listen to an
/// audio explanation and view a concept map. Upon completion, they
/// navigate to the progress screen using a named route (not
/// replacement) to preserve navigation history.
class DeepUnderstandingScreen extends StatefulWidget {
  const DeepUnderstandingScreen({super.key});

  @override
  State<DeepUnderstandingScreen> createState() => _DeepUnderstandingScreenState();
}

class _DeepUnderstandingScreenState extends State<DeepUnderstandingScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    try {
      final url = Uri.parse('http://10.0.2.2:8000/study-mode');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': provider.text, 'mode': 'concept_map'}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        provider.setConceptMap(data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load concept map')),
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
    final map = context.watch<ContentProvider>().conceptMap;
    return Scaffold(
      appBar: AppBar(title: const Text('Deep Understanding')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(map != null ? map.toString() : 'No concept map'),
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