import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

/// Allows the user to pick an existing audio file and upload it.
class AudioPickerScreen extends StatefulWidget {
  const AudioPickerScreen({super.key});

  @override
  State<AudioPickerScreen> createState() => _AudioPickerScreenState();
}

class _AudioPickerScreenState extends State<AudioPickerScreen> {
  String? _path;
  String? _name;
  Uint8List? _bytes;

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'aac'],
      withData: true,
    );
    if (!mounted) return;
    if (result != null && result.files.single.path != null) {
      setState(() {
        _path = result.files.single.path;
        _name = result.files.single.name;
        _bytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _continue() async {
    if (_bytes == null || _path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio file selected.')),
      );
      return;
    }

    final provider = context.read<ContentProvider>();
    provider.setAudioPath(_path!);

    try {
      final url = Uri.parse('http://10.0.2.2:8000/upload-content');
      final request = http.MultipartRequest('POST', url)
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            _bytes!,
            filename: _name ?? 'audio',
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
      appBar: AppBar(title: const Text('Upload Audio')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_name != null)
              Card(
                color: AppTheme.accentGray,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.audiotrack, color: AppTheme.accentTeal),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _name!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            PrimaryButton(
              label: 'Choose Audio',
              onPressed: _pickAudio,
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
                onPressed: _bytes != null ? _continue : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No audio file selected.')),
                  );
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

