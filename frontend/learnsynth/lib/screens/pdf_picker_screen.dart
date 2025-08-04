import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';

/// Allows the user to pick a PDF file and extract its text locally.
class PdfPickerScreen extends StatefulWidget {
  const PdfPickerScreen({super.key});

  @override
  State<PdfPickerScreen> createState() => _PdfPickerScreenState();
}

class _PdfPickerScreenState extends State<PdfPickerScreen> {
  File? _file;
  String? _text;
  bool _isProcessing = false;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (!mounted) return;
    if (result == null || result.files.single.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
      return;
    }

    _file = File(result.files.single.path!);
    setState(() {
      _isProcessing = true;
      _text = null;
    });

    try {
      final bytes = await _file!.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final extracted = PdfTextExtractor(document).extractText();
      document.dispose();
      if (!mounted) return;
      context.read<ContentProvider>().setContent(extracted);
      setState(() {
        _text = extracted;
        _isProcessing = false;
      });
    } catch (e) {
      _showError('Failed to process PDF');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _continue() {
    Navigator.pushNamed(context, Routes.loading);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload PDF')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PrimaryButton(
              label: 'Choose PDF',
              onPressed: _isProcessing ? null : _pickPdf,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Continue',
              onPressed: (_text != null && !_isProcessing) ? _continue : null,
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}

