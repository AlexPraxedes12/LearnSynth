import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/transcription_service.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../widgets/primary_button.dart';

/// Screen that lets the user pick an audio file, convert and transcribe it
/// locally for analysis.
class AudioPickerScreen extends StatefulWidget {
  const AudioPickerScreen({super.key});

  @override
  State<AudioPickerScreen> createState() => _AudioPickerScreenState();
}

class _AudioPickerScreenState extends State<AudioPickerScreen> {
  File? _selectedFile;
  bool _isProcessing = false;
  String? _transcript;

  Future<void> _pickAudio() async {
    try {
      if (Platform.isAndroid) {
        if (await Permission.audio.isDenied &&
            await Permission.storage.isDenied) {
          await [Permission.audio, Permission.storage].request();
        }
      }

      final XFile? result = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(label: 'audio', extensions: ['mp3', 'wav', 'm4a']),
        ],
      );
      if (result == null) {
        _showError('No file selected.');
        return;
      }
      _selectedFile = File(result.path);
      setState(() {
        _isProcessing = true;
        _transcript = null;
      });

      final ffmpegResult = await TranscriptionService().transcribeAudio(
        _selectedFile!,
      );
      if (!ffmpegResult.isSuccess) {
        _showError('Transcription failed');
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      final transcription = ffmpegResult.data ?? '';
      if (transcription.trim().isEmpty) {
        _showError('No text produced.');
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      if (!mounted) return;
      context.read<ContentProvider>().setFileContent(
        path: _selectedFile!.path,
        content: transcription,
      );
      setState(() {
        _transcript = transcription;
        _isProcessing = false;
      });
    } catch (e) {
      _showError(e.toString());
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _continue() {
    Navigator.pushNamed(context, Routes.loading);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
              label: 'Select Audio',
              onPressed: _isProcessing ? null : _pickAudio,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Continue',
              onPressed: (_transcript != null && !_isProcessing)
                  ? _continue
                  : null,
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
