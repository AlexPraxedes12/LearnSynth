import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learnsynth/l10n/app_localizations.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../widgets/settings_button.dart';
import '../core/connectivity.dart';
import '../utils/file_pickers.dart';

class AudioPickerScreen extends StatefulWidget {
  const AudioPickerScreen({super.key});

  @override
  State<AudioPickerScreen> createState() => _AudioPickerScreenState();
}

class _AudioPickerScreenState extends State<AudioPickerScreen> {
  Future<void> _choose() async {
    if (!await hasInternet()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Requiere transcripción online')));
      return;
    }
    final picked = await pickAudio();
    if (!mounted || picked == null) return;
    final p = context.read<ContentProvider>();
    p.setSelectedAudio(picked);
    Navigator.of(context).pushNamed(AppRoutes.analyzing);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(app.uploadAudio),
        actions: const [SettingsButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _choose,
              child: Text(app.chooseAudio),
            ),
          ),
        ),
      ),
    );
  }
}
