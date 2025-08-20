import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

/// A service to handle audio/video transcription using Vosk and FFmpeg.
class TranscriptionService {
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();

  /// Transcribes the audio from a given media file [file].
  ///
  /// This method handles both audio and video files. It uses FFmpeg to extract
  /// the audio and convert it to a WAV format (16kHz, mono, 16-bit PCM)
  /// that is compatible with the Vosk model.
  ///
  /// Returns the transcribed text as a [String].
  ///
  /// In case of an error during the process (e.g., file format not supported,
  /// FFmpeg failure, transcription error), it returns a user-friendly
  /// error message.
  Future<String> transcribeFile(File file) async {
    // 1. Set up temporary file path for the WAV output.
    final tempDir = await getTemporaryDirectory();
    final tempWavPath = p.join(
      tempDir.path,
      '${DateTime.now().millisecondsSinceEpoch}_temp_transcription.wav',
    );
    final tempWavFile = File(tempWavPath);

    try {
      // 2. Use FFmpeg to convert the input file to the required WAV format.
      // -y: Overwrite output file if it exists.
      // -i: Input file path.
      // -ar 16000: Set audio sample rate to 16kHz.
      // -ac 1: Set audio channels to 1 (mono).
      // -c:a pcm_s16le: Set audio codec to 16-bit PCM (little-endian).
      final command =
          '-y -i "${file.path}" -ar 16000 -ac 1 -c:a pcm_s16le "$tempWavPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      // 3. Check if FFmpeg execution was successful.
      if (!ReturnCode.isSuccess(returnCode)) {
        // Provide detailed logs for debugging if FFmpeg fails.
        final logs = await session.getAllLogsAsString();
        debugPrint('FFmpeg failed with return code $returnCode. Logs: $logs');
        throw Exception(
          'Error processing media file. FFmpeg returned a non-success code.',
        );
      }

      // 4. Verify that the temporary WAV file was created.
      if (!await tempWavFile.exists()) {
        throw Exception('Converted WAV file not found at path: $tempWavPath');
      }

      // 5. Load the Vosk model from assets.
      // The path 'assets/vosk/model' must match the one in pubspec.yaml.
      final model = await _vosk.createModel('assets/vosk/model');

      // 6. Create a recognizer with the loaded model and required sample rate.
      final recognizer = await _vosk.createRecognizer(
        model: model,
        sampleRate: 16000,
      );

      // 7. Read the audio data and process it with the recognizer.
      final audioBytes = await tempWavFile.readAsBytes();
      await recognizer.acceptWaveformBytes(audioBytes);
      final resultJson = await recognizer.getFinalResult();

      // 8. Parse the JSON result from Vosk to extract the transcribed text.
      final result = jsonDecode(resultJson);
      return result['text'] as String? ?? '';
    } catch (e) {
      // 9. Catch any exception, log it, and return a user-friendly error message.
      debugPrint('An error occurred during the transcription process: $e');
      return 'Error: Could not transcribe the file. Please check the file format and try again.';
    } finally {
      // 10. Clean up: delete the temporary WAV file in all cases.
      if (await tempWavFile.exists()) {
        await tempWavFile.delete();
      }
    }
  }
}
