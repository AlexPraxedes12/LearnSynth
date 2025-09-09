import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfImportResult {
  final String text;
  final bool isProbablyScanned; // true si no se extrajo texto útil
  PdfImportResult(this.text, this.isProbablyScanned);
}

class PdfImporter {
  /// Extrae texto embebido de un PDF (sin OCR). Offline.
  static Future<PdfImportResult> extractTextFromFile(File file,
      {int minUsefulLen = 200}) async {
    final bytes = await file.readAsBytes();
    final doc = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(doc);
    final text = extractor.extractText() ?? '';
    doc.dispose();
    final cleaned = text.replaceAll('\u0000', '').trim();
    print('PDF text length: ${cleaned.length}');
    print('First 200 chars: ${cleaned.substring(0, min(200, cleaned.length))}');
    if (cleaned.isEmpty || cleaned.length < 50) {
      throw Exception('PDF extraction failed: insufficient text');
    }
    final isScanned = cleaned.length < minUsefulLen;
    return PdfImportResult(cleaned, isScanned);
  }

  /// Extracts embedded text from PDF [bytes] without OCR. Offline.
  static Future<PdfImportResult> extractTextFromBytes(Uint8List bytes,
      {int minUsefulLen = 200}) async {
    final doc = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(doc);
    final text = extractor.extractText() ?? '';
    doc.dispose();
    final cleaned = text.replaceAll('\u0000', '').trim();
    print('PDF text length: ${cleaned.length}');
    print('First 200 chars: ${cleaned.substring(0, min(200, cleaned.length))}');
    if (cleaned.isEmpty || cleaned.length < 50) {
      throw Exception('PDF extraction failed: insufficient text');
    }
    final isScanned = cleaned.length < minUsefulLen;
    return PdfImportResult(cleaned, isScanned);
  }
}
