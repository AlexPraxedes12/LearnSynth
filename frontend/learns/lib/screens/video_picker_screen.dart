import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../widgets/wide_button.dart';
import 'file_transcribe_screen.dart';

class VideoPickerScreen extends StatelessWidget {
  const VideoPickerScreen({super.key});

  static const XTypeGroup _typeGroup = XTypeGroup(
    label: 'Video',
    extensions: ['mp4', 'mov', 'mkv', 'avi', 'webm'],
  );

  Future<void> _pick(BuildContext context) async {
    final x = await openFile(acceptedTypeGroups: [_typeGroup]);
    if (x == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FileTranscribeScreen(
          appBarTitle: 'Upload Video',
          file: File(x.path),
          typeGroup: _typeGroup,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Spacer(),
            WideButton(
              label: 'Choose Video',
              onPressed: () => _pick(context),
            ),
          ],
        ),
      ),
    );
  }
}
