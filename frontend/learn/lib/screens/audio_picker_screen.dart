import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/transcription_service.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../widgets/primary_button.dart';

/// Screen that lets the user pick an audio file and transcribe it locally for
/// analysis.
class AudioPickerScreen extends StatefulWidget {
  const AudioPickerScreen({super.key});

  @override
  State<AudioPickerScreen> createState() => _AudioPickerScreenState();
}

class _AudioPickerScreenState extends State<AudioPickerScreen> {
  final TranscriptionService _transcriptionService = TranscriptionService();
  File? _audioFile;
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
      _audioFile = File(result.path);
      setState(() {
        _isProcessing = true;
        _transcript = null;
      });

      final text = await _transcriptionService.transcribeFile(_audioFile!);
      if (!mounted) return;
      context.read<ContentProvider>().setFileContent(
        path: _audioFile!.path,
        content: text,
      );
      setState(() {
        _transcript = text;
        _isProcessing = false;
      });
    } catch (e) {
      _showError('Transcription failed');
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
          children: [
            if (_audioFile != null)
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
                        _audioFile!.path.split('/').last,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_audioFile!.path),
                    ],
                  ),
                ),
              ),
            if (_transcript != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: SizedBox(
                  height: 150,
                  child: SingleChildScrollView(
                    child: Text(_transcript!),
                  ),
                ),
              ),
            const Spacer(),
            PrimaryButton(
              label: 'Select Audio',
              onPressed: _isProcessing ? null : _pickAudio,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Continue',
              onPressed:
                  (_transcript != null && !_isProcessing) ? _continue : null,
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
