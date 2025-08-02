import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../widgets/primary_button.dart';

/// Screen that lets the user select an audio file, compress it and upload it
/// to the backend. The backend returns cleaned text which is stored in
/// [ContentProvider] for later processing.
class AudioPickerScreen extends StatefulWidget {
  const AudioPickerScreen({super.key});

  @override
  State<AudioPickerScreen> createState() => _AudioPickerScreenState();
}

class _AudioPickerScreenState extends State<AudioPickerScreen> {
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
        final file = File(result.files.single.path!);
        final compressed = await _compressAudio(file);
        if (compressed != null) {
          await _uploadAudio(compressed);
        } else {
          _showError('Compression failed');
        }
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<File?> _compressAudio(File input) async {
    try {
      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/compressed_audio.mp3';
      await FFmpegKit.execute('-i "${input.path}" -b:a 64k -y "$outPath"');
      final output = File(outPath);
      return output.existsSync() ? output : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _uploadAudio(File file) async {
    setState(() => _isProcessing = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/upload-audio'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final cleanedText = data['cleaned_text'] as String? ?? '';
        context.read<ContentProvider>().setText(cleanedText);
        if (mounted) {
          Navigator.pushNamed(context, Routes.loading);
        }
      } else {
        _showError('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Upload failed');
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
              label: 'Select Audio File',
              onPressed: _isProcessing ? null : _pickAudio,
            ),
          ],
        ),
      ),
    );
  }
}

