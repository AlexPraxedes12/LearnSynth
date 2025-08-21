import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../content_provider.dart';
import '../services/transcription_service.dart';
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
  String? _error;
  bool _busy = false;
  bool _analyzing = false;

  final _svc = TranscriptionService();

  Future<void> _pick() async {
    if (_busy || _analyzing) return;
    final x = await openFile(acceptedTypeGroups: [widget.fileTypeGroup]);
    if (x == null) return;
    if (!mounted) return;
    setState(() {
      _picked = File(x.path);
      _result = null;
    });
  }

  Future<void> _run() async {
    if (_busy) return;
    final f = _picked;
    if (f == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    String out;
    try {
      out = await _svc.sendFile(f);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = out;
    });

    // Persist transcript in Provider for later analysis
    context.read<ContentProvider>().setTranscript(out);
  }

  Future<void> _continueToAnalysis() async {
    if (_analyzing) return;
    setState(() => _analyzing = true);

    try {
      await context.read<ContentProvider>().runAnalysis();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _analyzing = false;
        _error = e.toString();
      });
      return;
    }

    if (!mounted) return;
    setState(() => _analyzing = false);

    // Navigate only if still mounted
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AnalysisScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canTranscribe = !_busy && _picked != null && _result == null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.appBarTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_picked != null) ...[
              Text(p.basename(_picked!.path),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_picked!.path,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 16),
            ],

            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),

            const Spacer(),

            // Choose File (always enabled unless busy/analyzing)
            ElevatedButton(
              onPressed: _busy || _analyzing ? null : _pick,
              child: Text(widget.buttonLabel),
            ),
            const SizedBox(height: 12),

            // If there is NO transcript yet -> show Transcribe
            if (_result == null)
              ElevatedButton(
                onPressed: canTranscribe ? _run : null,
                child: _busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Transcribe'),
              ),

            // If there IS a transcript -> show Continue instead
            if (_result != null)
              ElevatedButton(
                onPressed: _analyzing ? null : _continueToAnalysis,
                child: _analyzing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Continue'),
              ),
          ],
        ),
      ),
    );
  }
}
