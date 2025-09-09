import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:learnsynth/l10n/app_localizations.dart';

import '../constants.dart';
import '../content_provider.dart';
import '../services/transcription_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/wide_button.dart';
import '../widgets/settings_button.dart';
import '../utils/file_pickers.dart';

class FileTranscribeScreen extends StatefulWidget {
  final String appBarTitle;
  final ({Uint8List bytes, String name}) file;
  final bool isAudio;
  const FileTranscribeScreen({
    super.key,
    required this.appBarTitle,
    required this.file,
    required this.isAudio,
  });

  @override
  State<FileTranscribeScreen> createState() => _FileTranscribeScreenState();
}

class _FileTranscribeScreenState extends State<FileTranscribeScreen> {
  bool _busy = false;
  String? _error;
  ({Uint8List bytes, String name})? _picked;

  final _svc = TranscriptionService();

  bool get _isAudio => widget.isAudio;

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
    bool retry = false;
    try {
      final out = await _svc.sendFileOrExtractLocally(
        bytes: _picked!.bytes,
        filename: _picked!.name,
      );
      if (!mounted) return;
      final provider = context.read<ContentProvider>();
      provider.setTranscript(out);
      provider.content = out;
    } catch (e) {
      final waiting = 'Esperando conexión con el servidor...';
      final base = AppLocalizations.of(context)!
          .transcriptionFailed('$e');
      final msg = e.toString().contains('Network error') ? waiting : base;
      setState(() => _error = msg);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        if (!e.toString().contains('Network error')) {
          retry = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  content: Text(msg),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Reintentar online')),
                  ],
                ),
              ) ??
              false;
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (retry) {
      await _run();
    }
  }

  Future<void> _startAuto() async {
    final provider = context.read<ContentProvider>();
    try {
      await provider.transcribeAndAnalyze(_picked!, context);
    } catch (e) {
      if (!mounted) return;
      final emsg = e.toString();
      final msg = emsg.contains('Network error')
          ? 'Esperando conexión con el servidor...'
          : (e is Exception)
              ? e.toString()
              : 'Analyze failed';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
    if (!mounted) return;
    if (!provider.canContinue) {
      final err = provider.lastError;
      final msg = 'Analyze failed: '
          '${err ?? AppLocalizations.of(context)!.analysisFailed}';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
    setState(() {});
  }

  Future<void> _pick() async {
    final picked = _isAudio ? await pickAudio() : await pickVideo();
    if (picked == null) return;
    setState(() {
      _picked = picked;
      _error = null;
      _busy = true;
    });
    try {
      if (_isAudio) {
        await context.read<ContentProvider>().transcribeAndAnalyze(picked, context);
      } else {
        final p = context.read<ContentProvider>();
        p.setSelectedVideo(picked);
        await p.runAnalysis(context);
      }
    } catch (e) {
      if (mounted) {
        final msg = (e is Exception) ? e.toString() : 'Analyze failed';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Analyze failed: $msg')));
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
    });
    final provider = context.read<ContentProvider>();
    if (!provider.canContinue) {
      final err = provider.lastError;
      final msg = 'Analyze failed: '
          '${err ?? AppLocalizations.of(context)!.analysisFailed}';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _goToStudyPack(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.studyPack);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppLocalizations.of(context)!;
    final p = context.watch<ContentProvider>();
    final hasPick = _picked != null;
    final transcriptExists = p.rawText?.isNotEmpty ?? false;
    final isBusy = p.isAnalyzing || _busy;
    final canContinue = p.canContinue && _picked != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appBarTitle),
        actions: const [SettingsButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_picked != null) ...[
              Text(
                _picked!.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
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
                    label: app.selectAudio,
                    onPressed: _busy ? null : _pick,
                  ),
                  const SizedBox(height: 12),
                  // Only render Continue AFTER a file is picked
                  if (hasPick)
                    WideButton(
                      label: p.isAnalyzing ? app.analyzingDots : app.continueLabel,
                      onPressed: (!p.isAnalyzing && p.canContinue)
                          ? () => _goToStudyPack(context)
                          : null,
                    ),
                ],
              )
            else ...[
              PrimaryButton(
                label: transcriptExists
                    ? (p.isAnalyzing ? app.analyzingDots : app.continueLabel)
                    : (_busy ? app.transcribingDots : app.transcribe),
                onPressed: transcriptExists
                    ? (p.isAnalyzing
                          ? null
                          : () async {
                              final ok = await context
                                  .read<ContentProvider>()
                                  .runAnalysis(context);
                              if (!context.mounted) return;
                              if (ok) {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.studyPack);
                              } else {
                                final msg =
                                    context.read<ContentProvider>().lastError ??
                                    app.unableToAnalyze;
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
