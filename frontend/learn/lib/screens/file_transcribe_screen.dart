import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../services/transcription_service.dart';

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
  File? _picked;
  String? _transcript;
  bool _busy = false;

  final _svc = TranscriptionService();

  Future<void> _pick() async {
    final xFile = await openFile(acceptedTypeGroups: [widget.fileTypeGroup]);
    if (xFile == null) return;
    setState(() {
      _picked = File(xFile.path);
      _transcript = null;
    });
  }

  Future<void> _run() async {
    if (_picked == null) return;
    setState(() => _busy = true);
    final text = await _svc.transcribeFile(_picked!);
    setState(() {
      _transcript = text;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.appBarTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_picked != null) ...[
            Text(p.basename(_picked!.path), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(_picked!.path, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 16),
          ],
          if (_transcript != null) ...[
            const Text('Transcript:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(child: SingleChildScrollView(child: Text(_transcript!))),
            const SizedBox(height: 16),
          ] else
            const Spacer(),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          FilledButton(onPressed: _pick, child: Text(widget.buttonLabel)),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: (_picked != null && !_busy) ? _run : null,
            child: const Text('Transcribe'),
          ),
        ]),
      ),
    );
  }
}
