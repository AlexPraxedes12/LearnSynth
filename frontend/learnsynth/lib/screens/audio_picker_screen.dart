import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_audio_compress/flutter_audio_compress.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

/// Allows the user to pick an audio file from the device.
class AudioPickerScreen extends StatefulWidget {
  const AudioPickerScreen({super.key});

  @override
  State<AudioPickerScreen> createState() => _AudioPickerScreenState();
}

class _AudioPickerScreenState extends State<AudioPickerScreen> {
  String? _path;
  String? _name;
  Uint8List? _bytes;
  final _audioCompressor = FlutterAudioCompress();
  static const int _maxSize = 5 * 1024 * 1024;

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'opus'],
      withData: true,
    );
    if (!mounted) return;
    if (result != null && result.files.single.path != null) {
      setState(() {
        _path = result.files.single.path!;
        _name = result.files.single.name;
        _bytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _continue() async {
    if (_bytes == null || _path == null) return;
    final provider = Provider.of<ContentProvider>(context, listen: false);
    provider.setAudioPath(_path!);

    if (_bytes!.length > _maxSize) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compressing audio...')),
        );
      }
      try {
        final file = await _audioCompressor.compressAudio(_path!);
        if (file != null) {
          final compressed = await file.readAsBytes();
          _bytes = compressed;
        }
      } catch (e) {
        debugPrint('Compression error: $e');
      }
      if (_bytes != null && _bytes!.length > _maxSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File still too large after compression'),
            ),
          );
        }
        return;
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio compressed')),
        );
      }
    }

    // TODO: show loading indicator while uploading

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
      // TODO: display an error message to the user
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
            if (_path != null)
              Card(
                color: AppTheme.accentGray,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_path ?? ''),
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
