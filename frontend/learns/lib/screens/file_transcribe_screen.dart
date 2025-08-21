import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../content_provider.dart';
import '../services/transcription_service.dart';
import '../widgets/wide_button.dart';
import 'analysis_screen.dart';

class FileTranscribeScreen extends StatefulWidget {
  final String appBarTitle;
  final String buttonLabel;
  final XTypeGroup typeGroup;
  const FileTranscribeScreen({
    super.key,
    required this.appBarTitle,
    required this.buttonLabel,
    required this.typeGroup,
  });

  @override
  State<FileTranscribeScreen> createState() => _FileTranscribeScreenState();
}

class _FileTranscribeScreenState extends State<FileTranscribeScreen> {
  bool _busy = false;
  String? _error;
  File? _picked;

  ContentProvider get _provider => context.read<ContentProvider>();
  final _svc = TranscriptionService();

  Future<void> _pick() async {
    if (_busy || _provider.analyzing) return;
    final x = await openFile(acceptedTypeGroups: [widget.typeGroup]);
    if (x == null) return;
    if (!mounted) return;
    setState(() {
      _picked = File(x.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasTranscript =
        context.select<ContentProvider, bool>((p) => (p.content?.isNotEmpty ?? false));
    final analyzing = context.watch<ContentProvider>().analyzing;
    final String cta = hasTranscript ? 'Continue' : 'Transcribe';
    final bool enabled = !_busy && !analyzing && (_picked != null);

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
            WideButton(
              label: widget.buttonLabel,
              onPressed: _busy || analyzing ? null : _pick,
            ),
            const SizedBox(height: 12),
            WideButton(
              label: cta,
              onPressed: !enabled
                  ? null
                  : () async {
                      if (!hasTranscript) {
                        setState(() {
                          _busy = true;
                          _error = null;
                        });
                        try {
                          final out = await _svc.sendFile(_picked!);
                          _provider.setTranscript(out);
                        } catch (e) {
                          setState(() => _error = 'Transcription failed: $e');
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      } else {
                        await _provider.runAnalysis(mode: widget.typeGroup.toStudyMode());
                        if (mounted && _provider.error == null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AnalysisScreen()),
                          );
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

extension on XTypeGroup {
  StudyMode toStudyMode() {
    return StudyMode.memorization;
  }
}
