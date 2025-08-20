import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

class TranscriptionService {
  Future<String> transcribeFile(File file) async {
    String? outputPath;
    Recognizer? recognizer;
    Model? model;

    try {
      final tempDir = await getTemporaryDirectory();
      outputPath =
          '${tempDir.path}/transcription_${DateTime.now().millisecondsSinceEpoch}.wav';

      final session = await FFmpegKit.execute(
          '-i "${file.path}" -ac 1 -ar 16000 -f wav "$outputPath"');
      final returnCode = await session.getReturnCode();
      if (returnCode == null || !ReturnCode.isSuccess(returnCode)) {
        throw Exception('Audio extraction failed');
      }

      model = await Model.fromAsset('assets/vosk/model');
      recognizer = Recognizer(model: model, sampleRate: 16000);

      final audioBytes = await File(outputPath).readAsBytes();
      recognizer.acceptWaveformBytes(audioBytes);

      final resultJson = await recognizer.getFinalResult();
      final text = (jsonDecode(resultJson)['text'] as String?) ?? '';
      return text;
    } catch (e) {
      return 'Transcription failed: $e';
    } finally {
      recognizer?.close();
      model?.close();
      if (outputPath != null) {
        final tempFile = File(outputPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    }
  }
}
