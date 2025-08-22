import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../services/transcription_service.dart';
import '../widgets/primary_button.dart';

class FileTranscribeScreen extends StatefulWidget {
  final String appBarTitle;
  final File file;
  final XTypeGroup typeGroup;
  const FileTranscribeScreen({
    super.key,
    required this.appBarTitle,
    required this.file,
    required this.typeGroup,
  });

  @override
  State<FileTranscribeScreen> createState() => _FileTranscribeScreenState();
}

class _FileTranscribeScreenState extends State<FileTranscribeScreen> {
  bool _busy = false;
  String? _error;
  File? _picked;

  final _svc = TranscriptionService();

  ContentProvider get _provider => context.read<ContentProvider>();

  @override
  void initState() {
    super.initState();
    _picked = widget.file;
  }

  Future<void> _run() async {
    if (_picked == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final out = await _svc.sendFile(_picked!);
      if (!mounted) return;
      final provider = context.read<ContentProvider>();
      provider.setTranscript(out);
      provider.content = out;
    } catch (e) {
      setState(() => _error = 'Transcription failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Analysis is triggered directly from the button using [_provider].

  @override
  Widget build(BuildContext context) {
    final transcriptExists =
        context.select<ContentProvider, bool>((p) => p.rawText?.isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(title: Text(widget.appBarTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_picked != null) ...[
              Text(
                p.basename(_picked!.path),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                _picked!.path,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 16),
            ],
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const Spacer(),
            if (context.watch<ContentProvider>().isAnalyzing)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            PrimaryButton(
              label: transcriptExists
                  ? (context.watch<ContentProvider>().isAnalyzing ? 'Analyzing…' : 'Continue')
                  : (_busy ? 'Transcribing…' : 'Transcribe'),
              onPressed: transcriptExists
                  ? context.watch<ContentProvider>().isAnalyzing
                      ? null
                      : () async {
                          final ok = await _provider.runAnalysis();
                          if (!mounted) return;
                          if (ok) {
                            Navigator.of(context).pushNamed(Routes.studyPack);
                          } else {
                            final msg =
                                _provider.lastError ?? 'Analyze failed.';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                        }
                  : (!_busy ? _run : null),
            ),
          ],
        ),
      ),
    );
  }
}

