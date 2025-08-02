import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../content_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

/// Allows the user to record audio.
class AudioPickerScreen extends StatefulWidget {
  const AudioPickerScreen({super.key});

  @override
  State<AudioPickerScreen> createState() => _AudioPickerScreenState();
}

class _AudioPickerScreenState extends State<AudioPickerScreen> {
  FlutterSoundRecorder? _audioRecorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _path;

  @override
  void initState() {
    super.initState();
    initRecorder();
  }

  @override
  void dispose() {
    disposeRecorder();
    super.dispose();
  }

  Future<void> initRecorder() async {
    await _audioRecorder!.openRecorder();
    _isRecorderInitialized = true;
  }

  void disposeRecorder() {
    _audioRecorder!.closeRecorder();
    _audioRecorder = null;
  }

  Future<void> startRecordingAndCompressing() async {
    if (!_isRecorderInitialized) {
      return;
    }
    await _audioRecorder!.startRecorder(
      toFile: 'compressed_audio.aac',
      codec: Codec.aacADTS,
    );
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> stopRecording() async {
    final path = await _audioRecorder!.stopRecorder();
    setState(() {
      _isRecording = false;
      _path = path;
    });
  }

  Future<void> _continue() async {
    if (_path == null) return;
    final provider = Provider.of<ContentProvider>(context, listen: false);
    provider.setAudioPath(_path!);

    final file = File(_path!);
    final bytes = await file.readAsBytes();

    try {
      final url = Uri.parse('http://10.0.2.2:8000/upload-content');
      final request = http.MultipartRequest('POST', url)
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'audio.aac',
          ),
        );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = data['text'] as String? ?? '';
        provider.setFileContent(path: _path!, text: text);
      } else {
        debugPrint('Upload failed: ${response.statusCode}');
      }
    } catch (e, st) {
      debugPrint('Upload error: $e');
      debugPrintStack(stackTrace: st);
    }

    if (mounted) {
      Navigator.pushNamed(context, Routes.loading);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Audio')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_path != null)
              Text('Recording saved at: $_path')
            else if (_isRecording)
              const Text('Recording...'),
            const Spacer(),
            PrimaryButton(
              label: _isRecording ? 'Stop Recording' : 'Start Recording',
              onPressed: _isRecording ? stopRecording : startRecordingAndCompressing,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentTeal,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _path != null ? _continue : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
