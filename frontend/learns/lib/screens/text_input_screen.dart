import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:learnsynth/l10n/app_localizations.dart';
import '../widgets/wide_button.dart';
import '../constants.dart';
import '../content_provider.dart';
import '../widgets/settings_button.dart';

Widget _modeChip() {
  return ValueListenableBuilder<RunInfo>(
    valueListenable: currentRunInfo,
    builder: (context, info, _) {
      if (info.providerId.isEmpty) return const SizedBox.shrink();
      final label = info.providerId == 'backend'
          ? 'Online'
          : (info.providerId == 'offline'
              ? 'Offline (plugin)'
              : 'Offline (heurístico)');
      return Chip(
        label: Text('Modo: $label'),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    },
  );
}

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
    final provider = context.read<ContentProvider>();
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    provider.setTranscript(text);
    provider.content = text;
    if (mounted) {
      Navigator.pushNamed(context, AppRoutes.analyzing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(app.addTextTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: _modeChip()),
          ),
          const SettingsButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                color: Theme.of(context).colorScheme.surfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: app.enterTextHint,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            WideButton(label: app.continueLabel, onPressed: _onContinuePressed),
          ],
        ),
      ),
    );
  }
}
