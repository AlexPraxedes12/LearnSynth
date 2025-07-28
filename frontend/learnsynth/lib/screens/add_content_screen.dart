import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../widgets/method_card.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Lists the available ways to add new study content.
class AddContentScreen extends StatelessWidget {
  const AddContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final content = Provider.of<ContentProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Content')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            MethodCard(
              icon: Icons.text_fields,
              title: 'Paste Text',
              description: 'Type or paste plain text.',
              onTap: () => Navigator.pushNamed(context, Routes.textInput),
            ),
            const SizedBox(height: 16),
            MethodCard(
              icon: Icons.picture_as_pdf,
              title: 'Upload PDF',
              description: 'Pick a PDF document to analyse.',
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );
                if (result != null && result.files.single.path != null && context.mounted) {
                  content.setPdfPath(result.files.single.path!);
                  Navigator.pushNamed(context, Routes.loading);
                }
              },
            ),
            const SizedBox(height: 16),
            MethodCard(
              icon: Icons.mic,
              title: 'Upload Audio',
              description: 'Pick an audio file for transcription.',
              onTap: () => Navigator.pushNamed(context, Routes.audio),
            ),
            const SizedBox(height: 16),
            MethodCard(
              icon: Icons.video_file,
              title: 'Upload Video',
              description: 'Select a video for transcription.',
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(type: FileType.video);
                if (result != null && result.files.single.path != null && context.mounted) {
                  content.setVideoPath(result.files.single.path!);
                  Navigator.pushNamed(context, Routes.loading);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
