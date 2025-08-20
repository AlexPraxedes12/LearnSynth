import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

/// Service responsible for transcribing media files using FFmpeg and Vosk.
class TranscriptionService {
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();

  /// Transcribes the file located at [filePath].
  ///
  /// The input can be either an audio or video file. The audio stream is
  /// extracted and converted to a 16kHz mono WAV file before being processed
  /// by the Vosk recognizer.
  Future<String> transcribe(String filePath) async {
    final input = File(filePath);
    if (!await input.exists()) {
      return 'Error: Input file not found.';
    }

    final tempDir = await getTemporaryDirectory();
    final tempWavPath =
        p.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.wav');
    final tempWavFile = File(tempWavPath);

    try {
      final command =
          '-y -i "${input.path}" -ar 16000 -ac 1 -c:a pcm_s16le "$tempWavPath"';
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getAllLogsAsString();
        debugPrint('FFmpeg failed with code $returnCode. Logs: $logs');
        throw Exception('Error processing media file.');
      }

      if (!await tempWavFile.exists()) {
        throw Exception('Converted WAV file not found.');
      }

      final model = await _vosk.createModel('assets/vosk/model');
      final recognizer =
          await _vosk.createRecognizer(model: model, sampleRate: 16000);

      final audioBytes = await tempWavFile.readAsBytes();
      await recognizer.acceptWaveformBytes(audioBytes);
      final resultJson = await recognizer.getFinalResult();
      final result = jsonDecode(resultJson) as Map<String, dynamic>;
      return result['text'] as String? ?? '';
    } catch (e) {
      debugPrint('Transcription error: $e');
      return 'Error: Could not transcribe the file. Please check the file format and try again.';
    } finally {
      if (await tempWavFile.exists()) {
        await tempWavFile.delete();
      }
    }
  }
}

/// Entry point for running transcription in a background isolate via
/// [FlutterIsolate.spawn]. Expects [message] to contain the file path followed
/// by a [SendPort] to return the resulting transcript.
Future<void> transcriptionIsolate(List<dynamic> message) async {
  final String filePath = message[0] as String;
  final SendPort sendPort = message[1] as SendPort;

  final service = TranscriptionService();
  final result = await service.transcribe(filePath);
  Isolate.exit(sendPort, result);
}

