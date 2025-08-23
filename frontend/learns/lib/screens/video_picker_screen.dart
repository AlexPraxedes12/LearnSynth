import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../constants.dart';
import '../content_provider.dart';

class VideoPickerScreen extends StatefulWidget {
  const VideoPickerScreen({super.key});

  @override
  State<VideoPickerScreen> createState() => _VideoPickerScreenState();
}

class _VideoPickerScreenState extends State<VideoPickerScreen> {
  static const XTypeGroup _typeGroup = XTypeGroup(
    label: 'Video',
    extensions: ['mp4', 'mov', 'mkv', 'avi', 'webm'],
  );

  Future<File?> _selectVideo() async {
    final x = await openFile(acceptedTypeGroups: [_typeGroup]);
    return x == null ? null : File(x.path);
  }

  Future<void> _choose() async {
    final file = await _selectVideo();
    if (file == null) return;

    context.read<ContentProvider>().setSelectedVideo(file);
    Navigator.of(context).pushNamed(AppRoutes.analyzing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _choose,
              child: const Text('Choose Video'),
            ),
          ),
        ),
      ),
    );
  }
}
