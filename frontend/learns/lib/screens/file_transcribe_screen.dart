import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as pth;
import 'package:provider/provider.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../services/transcription_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/wide_button.dart';

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
    await provider.transcribeAndAnalyze(_picked!);
    if (!mounted) return;
    if (!provider.canContinue) {
      final msg = provider.lastError ?? 'Analysis failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
    setState(() {});
  }

  Future<void> _pick() async {
    final x = await openFile(acceptedTypeGroups: [widget.typeGroup]);
    if (x == null) return;
    final f = File(x.path);
    setState(() {
      _picked = f;
      _error = null;
      _busy = true;
    });
    await context.read<ContentProvider>().transcribeAndAnalyze(f);
    if (!mounted) return;
    setState(() {
      _busy = false;
    });
    final provider = context.read<ContentProvider>();
    if (!provider.canContinue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.lastError ?? 'Analysis failed',
          ),
        ),
      );
    }
  }

  void _goToStudyPack(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.studyPack);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ContentProvider>();
    final hasPick = _picked != null;
    final transcriptExists = p.rawText?.isNotEmpty ?? false;
    final isBusy = p.isAnalyzing || _busy;
    final canContinue = p.canContinue && _picked != null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.appBarTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_picked != null) ...[
              Text(
                pth.basename(_picked!.path),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Always show Select Audio
                  WideButton(
                    label: 'Select Audio',
                    onPressed: _busy ? null : _pick,
                  ),
                  const SizedBox(height: 12),
                  // Only render Continue AFTER a file is picked
                  if (hasPick)
                    WideButton(
                      label: p.isAnalyzing ? 'Analyzing…' : 'Continue',
                      onPressed: (!p.isAnalyzing && p.canContinue)
                          ? () => _goToStudyPack(context)
                          : null,
                    ),
                ],
              )
            else ...[
              PrimaryButton(
                label: transcriptExists
                    ? (p.isAnalyzing ? 'Analyzing…' : 'Continue')
                    : (_busy ? 'Transcribing…' : 'Transcribe'),
                onPressed: transcriptExists
                    ? (p.isAnalyzing
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
              if (p.isAnalyzing)
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
