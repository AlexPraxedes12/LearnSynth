import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/method_card.dart';
import '../constants.dart';

// Updated to use MethodCard widgets with file_picker for a more
// consistent, card-based design similar to the method selection screen.

/// Allows the user to add new content via multiple methods: pasting text,
/// uploading a PDF, recording audio or uploading a video. Each option now
/// opens an input picker before showing the processing screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                if (result != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selected ${result.files.single.name}')),
                  );
                  Navigator.pushNamed(context, Routes.processing);
                }
              },
            ),
            const SizedBox(height: 16),
            MethodCard(
              icon: Icons.mic,
              title: 'Record Audio',
              description: 'Select an audio file.',
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(type: FileType.audio);
                if (result != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selected ${result.files.single.name}')),
                  );
                  Navigator.pushNamed(context, Routes.processing);
                }
              },
            ),
            const SizedBox(height: 16),
            MethodCard(
              icon: Icons.video_file,
              title: 'Upload Video',
              description: 'Select a video for transcription.',
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(type: FileType.video);
                if (result != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Selected ${result.files.single.name}')),
                  );
                  Navigator.pushNamed(context, Routes.processing);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}