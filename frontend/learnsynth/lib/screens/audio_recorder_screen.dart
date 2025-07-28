import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Simple audio recorder using the `record` package.
class AudioRecorderScreen extends StatefulWidget {
  const AudioRecorderScreen({super.key});

  @override
  State<AudioRecorderScreen> createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  final Record _record = Record();
  bool _isRecording = false;

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _record.stop();
      if (path != null && context.mounted) {
        Provider.of<ContentProvider>(context, listen: false).setAudioPath(path);
        Navigator.pushNamed(context, Routes.loading);
      }
    } else {
      await _record.start();
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
