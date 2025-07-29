import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:provider/provider.dart';
import '../widgets/primary_button.dart';
import '../theme/app_theme.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Provides a multiline text field for users to paste or type text.
/// After continuing a short loading screen is shown before
/// navigating to the analysis stage.
class TextInputScreen extends StatefulWidget {
  const TextInputScreen({super.key});

  @override
  State<TextInputScreen> createState() => _TextInputScreenState();
}

class _TextInputScreenState extends State<TextInputScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // After tapping Continue we store the text and show a loading screen
  // before navigating to analysis.
  Future<void> _onContinuePressed() async {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    final text = _controller.text;

    try {
      final url = Uri.parse("http://10.0.2.2:8000/analyze");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final cleanedText = data['cleaned_text'] as String? ?? '';
        provider.setText(cleanedText);
        if (mounted) {
          Navigator.pushNamed(context, Routes.loading);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload content')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Network error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Text')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                color: AppTheme.accentGray,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Enter or paste text here',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Continue', onPressed: _onContinuePressed),
          ],
        ),
      ),
    );
  }
}
