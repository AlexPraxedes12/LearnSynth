import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Allows the user to pick a PDF file and reads its text.
class PdfPickerScreen extends StatelessWidget {
  const PdfPickerScreen({super.key});

  Future<void> _pickPdf(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null && context.mounted) {
      final path = result.files.single.path!;
      String text = 'PDF selected: ${result.files.single.name}';
      try {
        text = await File(path).readAsString();
      } catch (_) {}
      Provider.of<ContentProvider>(context, listen: false).setText(text);
      Navigator.pushNamed(context, Routes.loading);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload PDF')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: PrimaryButton(
            label: 'Choose PDF',
            onPressed: () => _pickPdf(context),
          ),
        ),
      ),
    );
  }
}
