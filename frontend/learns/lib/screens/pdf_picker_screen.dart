import 'package:flutter/material.dart';
import 'package:learnsynth/l10n/app_localizations.dart';

import '../widgets/wide_button.dart';
import '../widgets/settings_button.dart';
import '../constants.dart';
import '../content_provider.dart';
import '../services/transcription_service.dart';
import 'package:provider/provider.dart';
import '../utils/file_pickers.dart';

class PdfPickerScreen extends StatelessWidget {
  const PdfPickerScreen({super.key});

  Future<void> _pick(BuildContext context) async {
    final app = AppLocalizations.of(context)!;
    final picked = await pickPdf();
    if (picked == null) return;
    final provider = context.read<ContentProvider>();
    try {
      final text = await TranscriptionService().sendFileOrExtractLocally(
        bytes: picked.bytes,
        filename: picked.name,
      );
      provider.setTranscript(text);
      provider.content = text;
      if (!context.mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.analyzing);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString();
      if (msg.contains('file_too_large')) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(app.fileTooLarge)));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(app.transcriptionFailed(msg))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(app.uploadDocument),
        actions: const [SettingsButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Spacer(),
            Text(app.maxUploadSize),
            const SizedBox(height: 16),
            WideButton(
              label: app.selectPdf,
              onPressed: () => _pick(context),
            ),
          ],
        ),
      ),
    );
  }
}
