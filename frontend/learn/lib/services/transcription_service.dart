import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

class TranscriptionService {
  final FlutterSoundHelper _soundHelper = FlutterSoundHelper();

  Future<String> transcribeAudio(File file) async {
    // Ruta de salida WAV
    final outputPath =
        '${file.path}_${DateTime.now().millisecondsSinceEpoch}.wav';

    // Convertir a PCM16 WAV con flutter_sound
    await _soundHelper.convertFile(file.path, outputPath, Codec.pcm16WAV);

    // Cargar modelo offline de Vosk (asegúrate de ponerlo en assets/vosk/)
    final model = await Model.fromAsset('assets/vosk/model');

    // Crear recognizer con sampleRate = 16kHz
    final recognizer = Recognizer(model: model, sampleRate: 16000);

    // Leer audio y alimentar el recognizer
    final wavBytes = await File(outputPath).readAsBytes();
    recognizer.acceptWaveformBytes(wavBytes);

    // Obtener resultado
    final result = recognizer.finalResult();

    // Cerrar recognizer y modelo
    recognizer.close();
    model.close();

    return result.text;
  }
}
