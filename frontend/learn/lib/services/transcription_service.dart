// Cita del archivo subido: transcription_service.dart
import 'dart.convert';
import 'dart.io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

class TranscriptionService {
  final _vosk = VoskFlutterPlugin.instance();

  Future<String> transcribeFile(File file) async {
    final tempDir = await getTemporaryDirectory();
    final tempWavPath = p.join(
      tempDir.path,
      '${DateTime.now().millisecondsSinceEpoch}_temp_transcription.wav',
    );
    final tempWavFile = File(tempWavPath);

    try {
      final command =
          '-y -i "${file.path}" -ar 16000 -ac 1 -c:a pcm_s16le "$tempWavPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogsAsString();
        print('FFmpeg failed with return code $returnCode. Logs: $logs');
        throw Exception(
          'Error processing media file. FFmpeg returned non-zero exit code.',
        );
      }

      // CORRECCIÓN 1: Se crea el modelo a través de la instancia del plugin.
      final model = await _vosk.createModel('assets/vosk/model');

      // Se crea el reconocedor (esta parte estaba bien).
      final recognizer = await _vosk.createRecognizer(
        model: model,
        sampleRate: 16000,
      );

      final audioBytes = await tempWavFile.readAsBytes();
      await recognizer.acceptWaveformBytes(audioBytes);
      final resultJson = await recognizer.getFinalResult();

      // CORRECCIÓN 2: Se eliminan las llamadas a 'destroy' y 'close' que no existen.
      // La librería parece manejar esto automáticamente en esta versión.

      final result = jsonDecode(resultJson);
      return result['text'] as String? ?? '';
    } catch (e) {
      print('An error occurred during the transcription process: $e');
      return 'Error: Could not transcribe the file. Please check the file format and try again.';
    } finally {
      if (await tempWavFile.exists()) {
        await tempWavFile.delete();
      }
    }
  }
}
