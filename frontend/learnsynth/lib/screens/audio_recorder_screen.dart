import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Simple audio recorder using the `record` package.
class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  final _record = AudioRecorder();
  bool _isRecording = false;
  Future<void> requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      // Mostrar alerta o mensaje de error
      throw Exception("Microphone permission not granted");
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _record.stop();

      if (path != null && context.mounted) {
        Provider.of<ContentProvider>(context, listen: false).setAudioPath(path);
        Navigator.pushNamed(context, Routes.loading);
      }
    } else {
      await requestMicPermission();

      final dir = await getApplicationDocumentsDirectory();
      final filePath =
          '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _record.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
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
