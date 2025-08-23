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

  bool get _isAudio => widget.typeGroup.label!.toLowerCase() == 'audio';

  @override
  void initState() {
    super.initState();
    _picked = widget.file;
    if (_isAudio && _picked != null) {
      // Kick off transcription + analysis automatically
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAuto());
    }
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

  Future<void> _startAuto() async {
    final provider = context.read<ContentProvider>();
    final ok = await provider.transcribeAndAnalyze(_picked!);
    if (!mounted) return;
    if (!ok) {
      final msg = provider.lastError ?? 'Analysis failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    final transcriptExists = provider.rawText?.isNotEmpty ?? false;
    final isBusy = provider.isAnalyzing || _busy;
    final canContinue = provider.canContinue && _picked != null;

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
            if (_isAudio)
              PrimaryButton(
                label: isBusy ? 'Analyzing…' : 'Continue',
                onPressed: (!isBusy && canContinue)
                    ? () => Navigator.pushNamed(context, AppRoutes.studyPack)
                    : null,
              )
            else ...[
              PrimaryButton(
                label: transcriptExists
                    ? (provider.isAnalyzing ? 'Analyzing…' : 'Continue')
                    : (_busy ? 'Transcribing…' : 'Transcribe'),
                onPressed: transcriptExists
                    ? (provider.isAnalyzing
                          ? null
                          : () async {
                              final ok = await context
                                  .read<ContentProvider>()
                                  .runAnalysis();
                              if (!context.mounted) return;
                              if (ok) {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.studyPack);
                              } else {
                                final msg =
                                    context.read<ContentProvider>().lastError ??
                                    'Unable to analyze';
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(msg)));
                              }
                            })
                    : (!_busy ? _run : null),
              ),
              if (provider.isAnalyzing)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
            if (_isAudio && isBusy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
    );
  }
}
