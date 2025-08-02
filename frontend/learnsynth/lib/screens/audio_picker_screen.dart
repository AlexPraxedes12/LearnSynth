import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:whisper_dart/whisper_dart.dart' as whisper; // ignore: unused_import

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
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showError('Storage permission denied');
          return;
        }
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a'],
      );
      if (result != null && result.files.single.path != null) {
        _selectedFile = File(result.files.single.path!);
        setState(() {
          _isProcessing = true;
          _transcript = null;
        });

        final wavFile = await _ensureWav(_selectedFile!);
        final transcription = await _transcribeAudio(wavFile);
        if (!mounted) return;
        context.read<ContentProvider>().setText(transcription);
        setState(() {
          _transcript = transcription;
          _isProcessing = false;
        });
      }
    } catch (e) {
      _showError(e.toString());
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<File> _ensureWav(File file) async {
    final path = file.path;
    if (path.toLowerCase().endsWith('.wav')) {
      return file;
    }
    final outPath = '${path}_converted.wav';
    await FFmpegKit.execute('-i "$path" -ac 1 -ar 16000 "$outPath"');
    return File(outPath);
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

