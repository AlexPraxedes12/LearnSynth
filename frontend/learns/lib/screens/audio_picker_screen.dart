import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'file_transcribe_screen.dart';

class AudioPickerScreen extends StatelessWidget {
  const AudioPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FileTranscribeScreen(
      appBarTitle: 'Upload Audio',
      buttonLabel: 'Select Audio',
      fileTypeGroup: XTypeGroup(
        label: 'Audio',
        extensions: ['mp3', 'm4a', 'wav', 'flac', 'ogg', 'aac'],
      ),
      enableStudyPack: true,
    );
  }
}
