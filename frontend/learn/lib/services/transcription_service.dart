import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

class TranscriptionService {
  /// Transcribes an audio or video file using the Vosk offline speech recognition engine.
  ///
  /// This method takes a [File] (can be audio or video), extracts its audio stream,
  /// converts it to a 16kHz 16-bit mono PCM WAV format required by Vosk,
  /// performs the transcription, and cleans up temporary files.
  ///
  /// Returns the transcribed text as a [String].
  /// In case of an error, it returns a user-friendly error message.
  Future<String> transcribeFile(File file) async {
    final tempDir = await getTemporaryDirectory();
    // Create a unique path for the temporary WAV file to avoid conflicts.
    final tempWavPath = p.join(
      tempDir.path,
      '${DateTime.now().millisecondsSinceEpoch}_temp_transcription.wav',
    );
    final tempWavFile = File(tempWavPath);

    try {
      // Step 1: Convert the input file to the required WAV format using FFmpeg.
      // The command is robust enough to handle both audio and video files,
      // extracting the audio stream, resampling to 16kHz, and converting to mono PCM.
      final command =
          '-y -i "${file.path}" -ar 16000 -ac 1 -c:a pcm_s16le "$tempWavPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (!ReturnCode.isSuccess(returnCode)) {
        // The conversion failed. Log the details and throw an exception.
        final logs = await session.getAllLogsAsString();
        print('FFmpeg failed with return code $returnCode. Logs: $logs');
        throw Exception(
            'Error processing media file. FFmpeg returned non-zero exit code.');
      }

      // Step 2: Load the Vosk model from application assets.
      final model = await Model.fromAsset('assets/vosk/model');

      // Step 3: Create a recognizer instance with the model and required sample rate.
      final recognizer = Recognizer(model: model, sampleRate: 16000);

      // Step 4: Read the converted WAV file and feed its bytes to the recognizer.
      final audioBytes = await tempWavFile.readAsBytes();
      await recognizer.acceptWaveformBytes(audioBytes);

      // Step 5: Get the final transcription result (asynchronously).
      final resultJson = await recognizer.getFinalResult();

      // Step 6: Properly release native resources.
      recognizer.close();
      model.close();

      // Step 7: Parse the JSON result from Vosk and extract the transcribed text.
      // The result is typically in the format: {"text": "the transcribed text"}
      final result = jsonDecode(resultJson);
      return result['text'] as String? ?? '';
    } catch (e) {
      // Log the specific error for debugging purposes.
      print('An error occurred during the transcription process: $e');

      // Return a generic, user-friendly error message.
      return 'Error: Could not transcribe the file. Please check the file format and try again.';
    } finally {
      // Step 8: Clean up. Ensure the temporary file is deleted after the process.
      // This block executes whether the transcription succeeds or fails.
      if (await tempWavFile.exists()) {
        await tempWavFile.delete();
      }
    }
  }
}
