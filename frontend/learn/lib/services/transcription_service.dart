import 'dart:io';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

/// Provides audio transcription utilities backed by the Vosk speech
/// recognition engine.
class TranscriptionService {
  final FlutterSoundHelper _soundHelper = FlutterSoundHelper();

  /// Transcribes the given [file] and returns the recognized text.
  ///
  /// Video files have their audio track extracted before being processed.
  Future<String> transcribeFile(File file) async {
    File audioFile = file;

    final extension = file.path.split('.').last.toLowerCase();
    if (_videoExtensions.contains(extension)) {
      final outputPath =
          '${file.path}_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _soundHelper.convertFile(
        inputFile: file.path,
        outputFile: outputPath,
        codec: Codec.pcm16WAV,
        sampleRate: 16_000,
        numChannels: 1,
      );
      audioFile = File(outputPath);
    }

    final bytes = await audioFile.readAsBytes();

    final model = await Model.fromAsset('assets/vosk/model');
    final recognizer = Recognizer(model: model, sampleRate: 16_000);

    recognizer.acceptWaveform(bytes);
    final result = recognizer.finalResult();

    recognizer.close();
    model.close();

    if (audioFile.path != file.path) {
      await audioFile.delete();
    }

    return result;
  }

  static const Set<String> _videoExtensions = {
    'mp4',
    'mov',
    'avi',
    'mkv',
  };
}

