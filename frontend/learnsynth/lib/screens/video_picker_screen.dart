import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Picks a video file from the device.
class VideoPickerScreen extends StatelessWidget {
  const VideoPickerScreen({super.key});

  Future<void> _pickVideo(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null && context.mounted) {
      Provider.of<ContentProvider>(context, listen: false)
          .setVideoPath(result.files.single.path!);
      Navigator.pushNamed(context, Routes.loading);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: PrimaryButton(
            label: 'Choose Video',
            onPressed: () => _pickVideo(context),
          ),
        ),
      ),
    );
  }
}
