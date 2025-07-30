import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../widgets/primary_button.dart';
import '../constants.dart';
import '../content_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Allows the user to pick a PDF file and reads its text.
class PdfPickerScreen extends StatefulWidget {
  const PdfPickerScreen({super.key});

  @override
  State<PdfPickerScreen> createState() => _PdfPickerScreenState();
}

class _PdfPickerScreenState extends State<PdfPickerScreen> {
  bool _loading = false;

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

    final path = result.files.single.path!;
    final provider = Provider.of<ContentProvider>(context, listen: false);
    provider.setPdfPath(path);

    setState(() => _loading = true);

    try {
      final url = Uri.parse('http://10.0.2.2:8000/upload-content');
      final request = http.MultipartRequest('POST', url);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          path,
          contentType: MediaType('application', 'pdf'),
        ),
      );
      debugPrint('Uploading PDF to $url');

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text =
            (data['text'] ?? data['course'] ?? data['summary'] ?? '') as String;
        provider.setFileContent(path: path, text: text);
        if (mounted) {
          Navigator.pushNamed(context, Routes.loading);
        }
      } else {
        debugPrint('Upload failed: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload file')),
        );
      }
    } catch (e, st) {
      debugPrint('Upload error: $e');
      debugPrintStack(stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload PDF')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : PrimaryButton(
                  label: 'Choose PDF',
                  onPressed: _pickPdf,
                ),
        ),
      ),
    );
  }
}
