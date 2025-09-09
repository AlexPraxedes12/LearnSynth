import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learnsynth/l10n/app_localizations.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../widgets/settings_button.dart';
import '../core/connectivity.dart';
import '../utils/file_pickers.dart';

class VideoPickerScreen extends StatefulWidget {
  const VideoPickerScreen({super.key});

  @override
  State<VideoPickerScreen> createState() => _VideoPickerScreenState();
}

class _VideoPickerScreenState extends State<VideoPickerScreen> {
  Future<void> _choose() async {
    if (!await hasInternet()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Requiere transcripción online')));
      return;
    }
    final picked = await pickVideo();
    if (!mounted || picked == null) return;
    context.read<ContentProvider>().setSelectedVideo(picked);
    Navigator.of(context).pushNamed(AppRoutes.analyzing);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(app.uploadVideo),
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
              child: Text(app.chooseVideo),
            ),
          ),
        ),
      ),
    );
  }
}
