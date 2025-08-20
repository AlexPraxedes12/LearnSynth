import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/transcription_service.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../widgets/primary_button.dart';

class FileTranscribeScreen extends StatefulWidget {
  final String appBarTitle;
  final String buttonLabel;
  final XTypeGroup fileTypeGroup;

  const FileTranscribeScreen({
    super.key,
    required this.appBarTitle,
    required this.buttonLabel,
    required this.fileTypeGroup,
  });

  @override
  State<FileTranscribeScreen> createState() => _FileTranscribeScreenState();
}

class _FileTranscribeScreenState extends State<FileTranscribeScreen> {
  File? _file;
  bool _isProcessing = false;
  String? _transcript;

  Future<void> _pickFile() async {
    try {
      if (Platform.isAndroid) {
        // A bit of a hack, but we can infer the permission from the label.
        if (widget.fileTypeGroup.label == 'audio') {
          if (await Permission.audio.isDenied &&
              await Permission.storage.isDenied) {
            await [Permission.audio, Permission.storage].request();
          }
        } else if (widget.fileTypeGroup.label == 'video') {
          if (await Permission.videos.isDenied &&
              await Permission.storage.isDenied) {
            await [Permission.videos, Permission.storage].request();
          }
        }
      }

      final XFile? result = await openFile(
        acceptedTypeGroups: [widget.fileTypeGroup],
      );
      if (result == null) {
        _showError('No file selected.');
        return;
      }
      _file = File(result.path);
      setState(() {
        _isProcessing = true;
        _transcript = null;
      });

      final text = await compute(transcribeFileInBackground, _file!);
      if (!mounted) return;
      context.read<ContentProvider>().setFileContent(
        path: _file!.path,
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
      appBar: AppBar(title: Text(widget.appBarTitle)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (_file != null)
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
                        _file!.path.split('/').last,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(_file!.path),
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
              label: widget.buttonLabel,
              onPressed: _isProcessing ? null : _pickFile,
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
