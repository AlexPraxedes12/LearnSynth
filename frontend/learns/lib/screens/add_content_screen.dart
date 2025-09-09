import 'dart:async';

import 'package:flutter/material.dart';
import 'package:learnsynth/l10n/app_localizations.dart';

import '../widgets/method_card.dart';
import '../widgets/settings_button.dart';
import '../widgets/theme_toggle_button.dart';
import '../constants.dart';
import '../core/connectivity.dart';
import '../debug_llm_page.dart';

/// Lists the available ways to add new study content.
class AddContentScreen extends StatefulWidget {
  const AddContentScreen({super.key});

  @override
  State<AddContentScreen> createState() => _AddContentScreenState();
}

class _AddContentScreenState extends State<AddContentScreen> {
  int _tapCount = 0;
  Timer? _tapTimer;

  void _handleTitleTap() {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 500), () {
      _tapCount = 0;
    });
    if (_tapCount >= 3) {
      _tapCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DebugLlmPage()),
      );
    }
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _handleTitleTap,
          child: Text(app.addContent),
        ),
        actions: const [ThemeToggleButton(), SettingsButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            MethodCard(
              icon: Icons.text_fields,
              title: app.pasteText,
              description: app.pasteTextDesc,
              onTap: () => Navigator.pushNamed(context, Routes.textInput),
            ),
            const SizedBox(height: 16),
            MethodCard(
              icon: Icons.picture_as_pdf,
              title: app.uploadPdf,
              description: app.uploadPdfDesc,
              onTap: () => Navigator.pushNamed(context, Routes.pdfPicker),
            ),
            const SizedBox(height: 16),
            MethodCard(
              icon: Icons.mic,
              title: app.uploadAudio,
              description: app.uploadAudioDesc,
              onTap: () async {
                  if (await hasInternet()) {
                    // ignore: use_build_context_synchronously
                    Navigator.pushNamed(context, Routes.audio);
                  } else {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Requiere transcripción online')),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              MethodCard(
                icon: Icons.video_file,
              title: app.uploadVideo,
              description: app.uploadVideoDesc,
              onTap: () async {
                  if (await hasInternet()) {
                    // ignore: use_build_context_synchronously
                    Navigator.pushNamed(context, Routes.videoPicker);
                  } else {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Requiere transcripción online')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
    );
  }
}
