import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../services/transcription_service.dart';
import '../content_provider.dart';
import 'analysis_screen.dart';

class FileTranscribeScreen extends StatefulWidget {
  final String appBarTitle;
  final String buttonLabel;
  final XTypeGroup fileTypeGroup;
  final bool enableStudyPack;
  const FileTranscribeScreen({
    super.key,
    required this.appBarTitle,
    required this.buttonLabel,
    required this.fileTypeGroup,
    this.enableStudyPack = false,
  });

  @override
  State<FileTranscribeScreen> createState() => _FileTranscribeScreenState();
}

class _FileTranscribeScreenState extends State<FileTranscribeScreen> {
  File? _picked;
  String? _result;
  bool _busy = false;
  final _svc = TranscriptionService();

  Future<void> _pick() async {
    final x = await openFile(acceptedTypeGroups: [widget.fileTypeGroup]);
    if (x == null) return;
    setState(() {
      _picked = File(x.path);
      _result = null;
    });
  }

  Future<void> _run() async {
    final f = _picked;
    if (f == null) return;
    setState(() => _busy = true);
    final out = await _svc.sendFile(f);
    setState(() {
      _result = out;
      _busy = false;
    });
  }

  Future<void> _analyze() async {
    final txt = _result;
    if (txt == null) return;
    final p = context.read<ContentProvider>();
    p.setTranscript(txt);
    await p.runAnalysis();
    if (!mounted) return;
    if (p.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Analyze error: ${p.error}')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnalysisScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isErr = (_result ?? '').startsWith('Error:');
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
          if (_result != null) ...[
            const Text('Result:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_result!,
                    style: TextStyle(color: isErr ? Colors.red : null)),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.enableStudyPack && !isErr)
              FilledButton(
                onPressed: _analyze,
                child: const Text('Generate Study Pack'),
              ),
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
