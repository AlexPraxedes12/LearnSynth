import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/primary_button.dart';
import '../theme/app_theme.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Provides a multiline text field for users to paste or type text.
/// After continuing a short loading screen is shown before
/// navigating to the analysis stage.
class TextInputScreen extends ConsumerStatefulWidget {
  const TextInputScreen({super.key});

  @override
  ConsumerState<TextInputScreen> createState() => _TextInputScreenState();
}

class _TextInputScreenState extends ConsumerState<TextInputScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // After tapping Continue we store the text and show a loading screen
  // before navigating to analysis.
  Future<void> _onContinuePressed() async {
    final provider = ref.read(contentProvider);
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    provider.setContent(text);
    if (mounted) {
      Navigator.pushNamed(context, Routes.loading);
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
