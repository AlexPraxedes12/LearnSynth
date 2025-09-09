import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Picks an audio file and returns its bytes and name.
Future<({Uint8List bytes, String name})?> pickAudio() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['mp3', 'wav', 'ogg', 'flac', 'aac'],
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  Uint8List? bytes = file.bytes;
  if (bytes == null && file.path != null && !kIsWeb) {
    bytes = await File(file.path!).readAsBytes();
  }
  if (bytes == null) return null;
  return (bytes: bytes, name: file.name);
}

/// Picks a video file and returns its bytes and name.
Future<({Uint8List bytes, String name})?> pickVideo() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.video);
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  Uint8List? bytes = file.bytes;
  if (bytes == null && file.path != null && !kIsWeb) {
    bytes = await File(file.path!).readAsBytes();
  }
  if (bytes == null) return null;
  return (bytes: bytes, name: file.name);
}

/// Picks a PDF document and returns its bytes and name.
Future<({Uint8List bytes, String name})?> pickPdf() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  Uint8List? bytes = file.bytes;
  if (bytes == null && file.path != null && !kIsWeb) {
    bytes = await File(file.path!).readAsBytes();
  }
  if (bytes == null) return null;
  return (bytes: bytes, name: file.name);
}

