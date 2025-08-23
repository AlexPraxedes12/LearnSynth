import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

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

  Future<void> _pickAndAnalyze() async {
    final provider = context.read<ContentProvider>();
    final file = await _selectAudioFromDevice();
    if (file != null) {
      unawaited(provider.transcribeAndAnalyze(file));
    }
  }

  @override
  void dispose() {
    context.read<ContentProvider>().resetTranscribeFlow();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ContentProvider>();
    final hasFile = cp.selectedAudio != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Audio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasFile) ...[
              Text(
                p.basename(cp.selectedAudio!.path),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                cp.selectedAudio!.path,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 24),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (!hasFile && !cp.isAnalyzing) ? _pickAndAnalyze : null,
                child: const Text('Select Audio'),
              ),
            ),
            const SizedBox(height: 12),

            if (cp.isAnalyzing) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: null,
                  child: const Text('Analyzing...'),
                ),
              ),
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ] else if (cp.canContinue) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/studyPack');
                  },
                  child: const Text('Continue'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

