import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../content_provider.dart';

class AudioPickerScreen extends StatefulWidget {
  const AudioPickerScreen({super.key});

  @override
  State<AudioPickerScreen> createState() => _AudioPickerScreenState();
}

class _AudioPickerScreenState extends State<AudioPickerScreen> {
  static const XTypeGroup _typeGroup = XTypeGroup(
    label: 'Audio',
    extensions: ['mp3', 'm4a', 'wav', 'flac', 'ogg', 'aac'],
  );

  Future<File?> _selectAudioFromDevice() async {
    final x = await openFile(acceptedTypeGroups: [_typeGroup]);
    return x == null ? null : File(x.path);
  }

  Future<void> _choose() async {
    final File? file = await _selectAudioFromDevice();
    if (file == null) return;

    final p = context.read<ContentProvider>();
    p.setSelectedAudio(file);

    Navigator.of(context).pushNamed(AppRoutes.analyzing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Audio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _choose,
              child: const Text('Choose Audio'),
            ),
          ),
        ),
      ),
    );
  }
}
