import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'file_transcribe_screen.dart';

/// Screen that lets the user pick an audio file and transcribe it locally for
/// analysis.
class AudioPickerScreen extends StatelessWidget {
  const AudioPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FileTranscribeScreen(
      appBarTitle: 'Upload Audio',
      buttonLabel: 'Select Audio',
      fileTypeGroup: XTypeGroup(
        label: 'audio',
        extensions: ['mp3', 'wav', 'm4a'],
      ),
    );
  }
}
