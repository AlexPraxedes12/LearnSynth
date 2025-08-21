import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'file_transcribe_screen.dart';

class PdfPickerScreen extends StatelessWidget {
  const PdfPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FileTranscribeScreen(
      appBarTitle: 'Upload Document',
      buttonLabel: 'Select PDF',
      fileTypeGroup: XTypeGroup(
        label: 'PDF',
        extensions: ['pdf'],
      ),
    );
  }
}
