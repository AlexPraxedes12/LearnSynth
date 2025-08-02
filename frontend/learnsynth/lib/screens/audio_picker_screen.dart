import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../widgets/primary_button.dart';

/// Screen that lets the user pick an audio file, transcribe it locally and
/// upload the resulting text for analysis.
class AudioPickerScreen extends StatefulWidget {
  const AudioPickerScreen({super.key});

  @override
  State<AudioPickerScreen> createState() => _AudioPickerScreenState();
}

class _AudioPickerScreenState extends State<AudioPickerScreen> {
  File? _selectedFile;
  bool _isProcessing = false;

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
        setState(() {});
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<String> _transcribeAudio(File file) async {
    // TODO: Replace with real transcription using whisper_dart or platform channel.
    await Future.delayed(const Duration(seconds: 1));
    return 'Transcription placeholder';
  }

  Future<void> _continue() async {
    if (_selectedFile == null) return;
    setState(() => _isProcessing = true);
    try {
      final transcription = await _transcribeAudio(_selectedFile!);
      context
          .read<ContentProvider>()
          .setFileContent(path: _selectedFile!.path, text: transcription);

      final uploadRes = await http.post(
        Uri.parse('http://10.0.2.2:8000/upload-content'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': transcription}),
      );
      if (uploadRes.statusCode != 200) {
        _showError('Upload failed: ${uploadRes.statusCode}');
        return;
      }

      final analyzeRes = await http.post(
        Uri.parse('http://10.0.2.2:8000/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': transcription}),
      );

      if (analyzeRes.statusCode == 200) {
        final data = jsonDecode(analyzeRes.body) as Map<String, dynamic>;
        final summary = data['summary'] as String? ?? '';
        final topics = List<String>.from(data['topics'] as List? ?? []);
        context.read<ContentProvider>().setAnalysis(summary, topics);
        if (mounted) {
          Navigator.pushNamed(context, Routes.loading);
        }
      } else {
        _showError('Analysis failed: ${analyzeRes.statusCode}');
      }
    } catch (e) {
      _showError('Processing failed');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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
                  (_selectedFile != null && !_isProcessing) ? _continue : null,
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

