import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';
import '../services/transcription_service.dart';

/// Picks a video file, extracts the audio track, and transcribes it locally.
class VideoPickerScreen extends ConsumerStatefulWidget {
  const VideoPickerScreen({super.key});

  @override
  ConsumerState<VideoPickerScreen> createState() => _VideoPickerScreenState();
}

class _VideoPickerScreenState extends ConsumerState<VideoPickerScreen> {
  File? _videoFile;
  bool _isProcessing = false;
  String? _transcript;

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null || result.files.single.path == null) {
      _showError('No file selected.');
      return;
    }
    _videoFile = File(result.files.single.path!);
    setState(() {
      _isProcessing = true;
      _transcript = null;
    });

    try {
      final service = TranscriptionService();
      final audioResult = await service.extractAudioFromVideo(_videoFile!);
      if (!audioResult.isSuccess) {
        _showError('Audio extraction failed');
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      final audioFile = audioResult.data!;
      final textResult = await service.transcribeAudio(audioFile);
      if (!textResult.isSuccess) {
        _showError('Transcription failed');
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      final text = textResult.data ?? '';
      if (text.trim().isEmpty) {
        _showError('No text produced.');
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      if (!mounted) return;
      ref.read(contentProvider).setFileContent(
        path: _videoFile!.path,
        content: text,
      );
      setState(() {
        _transcript = text;
        _isProcessing = false;
      });
    } catch (e) {
      _showError('Processing failed');
      if (mounted) setState(() => _isProcessing = false);
    }
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

