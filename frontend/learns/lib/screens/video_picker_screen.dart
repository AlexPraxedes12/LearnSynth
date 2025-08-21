import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'file_transcribe_screen.dart';

class VideoPickerScreen extends StatelessWidget {
  const VideoPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FileTranscribeScreen(
      appBarTitle: 'Upload Video',
      buttonLabel: 'Choose Video',
      fileTypeGroup: XTypeGroup(label: 'Video', extensions: ['mp4', 'mov', 'mkv', 'avi', 'webm']),
    );
  }
}
