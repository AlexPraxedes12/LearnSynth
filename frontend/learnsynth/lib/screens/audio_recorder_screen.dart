import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';
import 'package:path_provider/path_provider.dart';

/// Simple audio recorder using the `record` package.
class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  final _record = AudioRecorder();
  bool _isRecording = false;

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _record.stop();

      if (path != null && context.mounted) {
        Provider.of<ContentProvider>(context, listen: false).setAudioPath(path);
        Navigator.pushNamed(context, Routes.loading);
      }
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _record.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc, // o .opus, .wav
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );
    }

    setState(() => _isRecording = !_isRecording);
  }

  @override
  void dispose() {
    _record.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Audio')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: PrimaryButton(
            label: _isRecording ? 'Stop Recording' : 'Start Recording',
            onPressed: _toggleRecording,
          ),
        ),
      ),
    );
  }
}
