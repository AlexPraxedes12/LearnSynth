import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import '../core/net/backend_client.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

import '../core/connectivity.dart';
import '../core/import/pdf_importer.dart';
import '../core/net/json_sugar.dart' show mapifyResponse;
import '../core/llm/analyze_result.dart';
import '../core/net/api_config.dart';

class TranscriptionService {
  // Backend endpoint
  final Uri _endpoint = Uri.parse('${ApiConfig.apiBase}/upload-content');

  Future<String> sendFile({required Uint8List bytes, required String filename}) async {
    final req = http.MultipartRequest('POST', _endpoint)
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    http.StreamedResponse res;
    try {
      res = await BackendClient.client
          .send(req)
          .timeout(ApiConfig.backendTimeout);
    } on SocketException catch (e) {
      throw Exception('Network error: $e');
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } on TimeoutException {
      throw Exception('upload timed out');
    }

    final body = await res.stream.bytesToString();

    if (res.statusCode == 400) {
      throw Exception('file_too_large');
    }
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: $body');
    }

    final map = jsonDecode(body) as Map<String, dynamic>;
    final txt = (map['text'] ?? '').toString();
    if (txt.trim().isNotEmpty) return txt;

    // For non-audio/video responses (e.g., course JSON), return raw JSON text
    return jsonEncode(map);
  }

  /// Sends the file to the backend or extracts text locally if offline and the
  /// file is a PDF with embedded text.
  ///
  /// Throws an [Exception] if the PDF appears to be scanned images.
  Future<String> sendFileOrExtractLocally(
      {required Uint8List bytes, required String filename}) async {
    final online = await hasInternet();
    final ext = p.extension(filename).toLowerCase();
    if (ext == '.pdf' && !online) {
      if (kIsWeb) {
        throw Exception(
            'La importación de PDFs sin conexión no está disponible en Web. Activa internet para continuar.');
      }
      final res = await PdfImporter.extractTextFromBytes(bytes);
      if (res.isProbablyScanned) {
        throw Exception(
            'Este PDF parece escaneado y requiere OCR. Activa internet para continuar.');
      }
      return res.text;
    }
    return sendFile(bytes: bytes, filename: filename);
  }

  // Calls the backend to analyze a block of [text] and returns the parsed result.
  // Throws an [Exception] if the request fails.
  Future<AnalyzeResult> analyzeText(String text,
      {String mode = 'memorization'}) async {
    final uri = Uri.parse('${ApiConfig.apiBase}/analyze');
    final resp = await BackendClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text, 'mode': mode, 'llm_provider': 'backend'}),
    );
    final bodyText = utf8.decode(resp.bodyBytes);
    if (resp.statusCode == 200) {
      final j = mapifyResponse(bodyText);
      final ok = (j['ok'] == true) || (j['status'] == 'ok');
      if (!ok) {
        debugPrint('[analyze] not ok: $bodyText');
        throw Exception(j['error'] ?? 'Analyze returned not ok');
      }
      return AnalyzeResult.fromJson(j);
    } else {
      debugPrint('[analyze] HTTP ${resp.statusCode}: $bodyText');
      throw Exception('HTTP ${resp.statusCode}');
    }
  }
}
