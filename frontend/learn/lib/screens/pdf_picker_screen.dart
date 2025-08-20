import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';

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
    final XFile? result = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(label: 'pdf', extensions: ['pdf']),
      ],
    );
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
      return;
    }

    _file = File(result.path);
    setState(() {
      _isProcessing = true;
      _text = null;
    });

    try {
      final document = await PdfDocument.openFile(_file!.path);
      String extracted = '';
      for (var i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        final text = await page.text;
        extracted += text ?? '';
        await page.close();
      }
      await document.close();
      if (!mounted) return;
      context.read<ContentProvider>().setFileContent(
        path: _file!.path,
        content: extracted,
      );
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

