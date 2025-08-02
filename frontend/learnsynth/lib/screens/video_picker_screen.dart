import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Picks a video file from the device.
class VideoPickerScreen extends StatefulWidget {
  const VideoPickerScreen({super.key});

  @override
  State<VideoPickerScreen> createState() => _VideoPickerScreenState();
}

class _VideoPickerScreenState extends State<VideoPickerScreen> {
  String? _path;
  String? _name;
  bool _isLoading = false;

  /// Placeholder method for local video transcription.
  /// In a real application, integrate a proper transcription library.
  Future<String> _transcribeVideo(String path) async {
    // TODO: Implement actual on-device transcription.
    // For now, return a mocked transcript so the flow can continue.
    return 'Transcribed text from video';
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    if (!mounted) return;
    if (result != null && result.files.single.path != null) {
      setState(() {
        _path = result.files.single.path;
        _name = result.files.single.name;
      });
    }
  }

  Future<void> _continue() async {
    if (_path == null) return;
    final provider = Provider.of<ContentProvider>(context, listen: false);
    provider.setVideoPath(_path!);
    setState(() => _isLoading = true);

    try {
      // 1. Transcribe the video locally.
      var transcript = await _transcribeVideo(_path!);

      // 2. Upload the transcript text to the backend.
      final uploadUrl = Uri.parse('http://10.0.2.2:8000/upload-content');
      final uploadRequest = http.MultipartRequest('POST', uploadUrl)
        ..files.add(
          http.MultipartFile.fromString(
            'file',
            transcript,
            filename: _name ?? 'transcript.txt',
          ),
        );
      final uploadStreamed = await uploadRequest.send();
      final uploadResponse = await http.Response.fromStream(uploadStreamed);
      if (uploadResponse.statusCode == 200) {
        final data = jsonDecode(uploadResponse.body) as Map<String, dynamic>;
        transcript = data['text'] as String? ?? transcript;
      } else {
        throw Exception('Upload failed: ${uploadResponse.statusCode}');
      }

      provider.setFileContent(path: _path!, text: transcript);

      // 3. Analyze the transcript.
      final analyzeUrl = Uri.parse('http://10.0.2.2:8000/analyze');
      final analyzeResponse = await http.post(
        analyzeUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': transcript}),
      );
      if (analyzeResponse.statusCode == 200) {
        final data = jsonDecode(analyzeResponse.body) as Map<String, dynamic>;
        final summary = data['summary'] as String? ?? '';
        final topics = List<String>.from(data['topics'] as List? ?? []);
        provider.setAnalysis(summary, topics);
        if (mounted) {
          Navigator.pushNamed(context, Routes.loading);
        }
      } else {
        throw Exception('Analysis failed: ${analyzeResponse.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_path != null)
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
                        _name ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_path ?? ''),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            PrimaryButton(
              label: 'Select Video',
              onPressed: _isLoading ? null : _pickVideo,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _path != null && !_isLoading ? _continue : null,
                child: _isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
