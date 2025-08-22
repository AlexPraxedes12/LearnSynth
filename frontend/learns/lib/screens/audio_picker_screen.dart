import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/wide_button.dart';
import '../content_provider.dart';
import '../constants.dart';
import 'file_transcribe_screen.dart';

class AudioPickerScreen extends StatelessWidget {
  const AudioPickerScreen({super.key});

  static const XTypeGroup _typeGroup = XTypeGroup(
    label: 'Audio',
    extensions: ['mp3', 'm4a', 'wav', 'flac', 'ogg', 'aac'],
  );

  Future<void> _pick(BuildContext context) async {
    final x = await openFile(acceptedTypeGroups: [_typeGroup]);
    if (x == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FileTranscribeScreen(
          appBarTitle: 'Upload Audio',
          file: File(x.path),
          typeGroup: _typeGroup,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContentProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Audio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Spacer(),
            WideButton(
              label: 'Select Audio',
              onPressed: () => _pick(context),
            ),
            const SizedBox(height: 16),
            WideButton(
              label: provider.isAnalyzing ? 'Analyzing…' : 'Continue',
              onPressed: provider.isAnalyzing
                  ? null
                  : () async {
                      final ok =
                          await context.read<ContentProvider>().runAnalysis();
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.of(context).pushNamed(Routes.studyPack);
                      } else {
                        final msg =
                            context.read<ContentProvider>().lastError ??
                                'Analysis failed';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(msg)),
                        );
                      }
                    },
            ),
            if (provider.isAnalyzing) ...[
              const SizedBox(height: 16),
              const Text('Analyzing…',
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ],
        ),
      ),
    );
  }
}
