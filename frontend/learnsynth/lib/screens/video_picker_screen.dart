import 'dart:convert';
import 'dart:typed_data';

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
  Uint8List? _bytes;
  static const int _maxSize = 5 * 1024 * 1024;

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );
    if (!mounted) return;
    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      if (file.size > _maxSize) {
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => const AlertDialog(
              content: Text(
                'The selected file is too large (max 5MB). Please choose a smaller file.',
              ),
            ),
          );
        }
        return;
      }
      setState(() {
        _path = file.path!;
        _name = file.name;
        _bytes = file.bytes;
      });
    }
  }

  Future<void> _continue() async {
    if (_bytes == null || _path == null) return;
    final provider = Provider.of<ContentProvider>(context, listen: false);
    provider.setVideoPath(_path!);

    if (_bytes!.length > _maxSize) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => const AlertDialog(
            content: Text(
              'The selected file is too large (max 5MB). Please choose a smaller file.',
            ),
          ),
        );
      }
      return;
    }

    // TODO: show loading indicator while uploading

    try {
      final url = Uri.parse('http://10.0.2.2:8000/upload-content');
      final request = http.MultipartRequest('POST', url)
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            _bytes!,
            filename: _name ?? 'video',
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
              label: 'Choose Video',
              onPressed: _pickVideo,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
