import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

class TranscriptionService {
  final FlutterSoundHelper _soundHelper = FlutterSoundHelper();

  Future<String> transcribeFile(File file) async {
    // 1. Convert file to PCM16 WAV
    final outputPath =
        '${file.path}_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _soundHelper.convertFile(
      file.path,
      outputPath,
      Codec.pcm16WAV,
    );

    // 2. Load Vosk model from assets
    final model = await Model.fromAsset('assets/vosk/model');

    // 3. Create recognizer with 16k sample rate
    final recognizer = Recognizer(model: model, sampleRate: 16000);

    // 4. Read audio file and send bytes to recognizer
    final audioBytes = await File(outputPath).readAsBytes();
    recognizer.acceptWaveformBytes(audioBytes);

    // 5. Get final result
    final result = recognizer.finalResult();

    // 6. Close recognizer and model
    recognizer.close();
    model.close();

    return result;
  }
}
