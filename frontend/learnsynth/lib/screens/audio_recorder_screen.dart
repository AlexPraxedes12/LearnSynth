import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Allows the user to pick an existing audio file.
class AudioRecorderScreen extends StatelessWidget {
  const AudioRecorderScreen({super.key});

  Future<void> _pickAudio(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'opus'],
    );
    if (result != null && result.files.single.path != null && context.mounted) {
      Provider.of<ContentProvider>(context, listen: false)
          .setAudioPath(result.files.single.path!);
      Navigator.pushNamed(context, Routes.loading);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Audio')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: PrimaryButton(
            label: 'Upload Audio',
            onPressed: () => _pickAudio(context),
          ),
        ),
      ),
    );
  }
}
