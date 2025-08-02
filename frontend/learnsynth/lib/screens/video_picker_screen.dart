import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:whisper_dart/whisper_dart.dart' as whisper; // ignore: unused_import

import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Picks a video file, extracts the audio track, and transcribes it locally.
class VideoPickerScreen extends StatefulWidget {
  const VideoPickerScreen({super.key});

  @override
  State<VideoPickerScreen> createState() => _VideoPickerScreenState();
}

class _VideoPickerScreenState extends State<VideoPickerScreen> {
  File? _videoFile;
  bool _isProcessing = false;
  String? _transcript;

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      _videoFile = File(result.files.single.path!);
      setState(() {
        _isProcessing = true;
        _transcript = null;
      });

      try {
        final audioPath = '${_videoFile!.path}_audio.wav';
        await FFmpegKit.execute(
            '-i "${_videoFile!.path}" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$audioPath"');
        final text = await _transcribeAudio(File(audioPath));
        if (!mounted) return;
        context.read<ContentProvider>().setText(text);
        setState(() {
          _transcript = text;
          _isProcessing = false;
        });
      } catch (e) {
        _showError('Processing failed');
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<String> _transcribeAudio(File file) async {
    // TODO: Replace with real transcription using whisper_dart or another STT package.
    await Future.delayed(const Duration(seconds: 1));
    return 'Transcription placeholder';
  }

  void _continue() {
    Navigator.pushNamed(context, Routes.loading);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_videoFile != null)
              Card(
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _videoFile!.path.split('/').last,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_videoFile!.path),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            PrimaryButton(
              label: 'Choose Video',
              onPressed: _isProcessing ? null : _pickVideo,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_transcript != null && !_isProcessing) ? _continue : null,
                child: const Text('Continue'),
              ),
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}

