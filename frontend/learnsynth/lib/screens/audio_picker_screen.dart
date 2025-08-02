import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../widgets/primary_button.dart';

/// Screen allowing the user to either record a new clip or pick an
/// existing audio file from device storage. Once a file is obtained it
/// is stored in [ContentProvider] and the user is taken to the loading
/// screen for processing.
class AudioPickerScreen extends StatefulWidget {
  const AudioPickerScreen({super.key});

  @override
  State<AudioPickerScreen> createState() => _AudioPickerScreenState();
}

class _AudioPickerScreenState extends State<AudioPickerScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _recorder.openRecorder();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stopRecorder();
      setState(() => _isRecording = false);
      if (path != null) {
        _handleSelected(File(path));
      }
    } else {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.startRecorder(toFile: path, codec: Codec.aacMP4);
      setState(() => _isRecording = true);
    }
  }

  Future<void> _pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a'],
    );
    if (result != null && result.files.single.path != null) {
      _handleSelected(File(result.files.single.path!));
    }
  }

  void _handleSelected(File file) {
    context.read<ContentProvider>().setAudioFile(file);
    Navigator.pushNamed(context, Routes.loading);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Audio')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PrimaryButton(
              label: _isRecording ? 'Stop Recording' : 'Record Audio',
              onPressed: _toggleRecording,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Choose from Files',
              onPressed: _pickFromFiles,
            ),
          ],
        ),
      ),
    );
  }
}

