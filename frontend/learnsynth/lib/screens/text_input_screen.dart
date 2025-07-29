import 'package:flutter/material.dart';
import '../services/content_service.dart';

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

  // Send the text to the backend and proceed to the loading screen.
  Future<void> _onContinuePressed() async {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    final text = _controller.text;

    try {
      final cleaned = await ContentService.uploadContent(text);
      provider.setText(cleaned);
      if (mounted) {
        Navigator.pushNamed(context, Routes.loading);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload text')),
        );
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
