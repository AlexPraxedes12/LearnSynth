import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Picks a video file and sends it to the backend for transcription.
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
      final uri = Uri.parse('http://10.0.2.2:8000/upload-content');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', _videoFile!.path));
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode != 200) {
        _showError('Processing failed');
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      final text = (data['text'] ?? '') as String;
      if (text.trim().isEmpty) {
        _showError('No text produced.');
        if (mounted) setState(() => _isProcessing = false);
        return;
      }
      if (!mounted) return;
      context.read<ContentProvider>().setFileContent(
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

