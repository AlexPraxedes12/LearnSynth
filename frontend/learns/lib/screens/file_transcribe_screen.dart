import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../content_provider.dart';
import '../services/transcription_service.dart';
import '../widgets/primary_button.dart';
import 'analysis_screen.dart';

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
  bool _analyzing = false;
  String? _error;
  File? _picked;

  final _svc = TranscriptionService();

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
      provider.rawText = out;
      provider.content = out;
    } catch (e) {
      setState(() => _error = 'Transcription failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continue() async {
    if (!mounted) return;
    final provider = context.read<ContentProvider>();
    try {
      setState(() => _analyzing = true);
      final url = Uri.parse('http://10.0.2.2:8000/analyze');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': provider.rawText ?? provider.content}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        provider.setAnalysis(data);
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AnalysisScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue =
        context.select<ContentProvider, bool>((p) => p.content?.isNotEmpty ?? false);

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
            PrimaryButton(
              label: canContinue
                  ? (_analyzing ? 'Analyzing…' : 'Continue')
                  : (_busy ? 'Transcribing…' : 'Transcribe'),
              onPressed: (canContinue && !_analyzing)
                  ? _continue
                  : (!canContinue && !_busy)
                      ? _run
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}

