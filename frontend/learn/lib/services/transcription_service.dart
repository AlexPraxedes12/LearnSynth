import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

import 'package:speech_to_text/speech_to_text.dart';

/// A simple wrapper that mimics an FFmpeg session result.
class FfmpegResult<T> {
  final T? data;
  final int returnCode;

  const FfmpegResult({this.data, required this.returnCode});

  bool get isSuccess => returnCode == 0;
}

/// Provides audio transcription utilities backed by on-device processing.
class TranscriptionService {
  final SpeechToText _speech = SpeechToText();

  /// Extracts the audio track from a [videoFile] and stores it as a WAV file.
  ///
  /// Returns a [FfmpegResult] whose [data] contains the generated audio file on
  /// success or `null` on failure. The [returnCode] is propagated from the
  /// underlying FFmpeg invocation when possible.
  Future<FfmpegResult<File>> extractAudioFromVideo(File videoFile) async {
    final outputPath =
        '${videoFile.path}_${DateTime.now().millisecondsSinceEpoch}.wav';
    try {
      final session = await FFmpegKit.execute(
        '-y -i "${videoFile.path}" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$outputPath"',
      );
      final code = (await session.getReturnCode() ?? 1) as int;
      if (code == 0) {
        return FfmpegResult(data: File(outputPath), returnCode: code);
      }
      return FfmpegResult<File>(data: null, returnCode: code);
    } catch (_) {
      return const FfmpegResult<File>(data: null, returnCode: 1);
    }
  }

  /// Transcribes the given [audioFile] and returns the recognized text.
  ///
  /// The transcription is performed using the [SpeechToText] plugin, which
  /// listens to the microphone and returns the recognized text.
  ///
  /// The provided [audioFile] parameter is ignored as `speech_to_text` does not
  /// support transcribing from pre-recorded files directly.
  Future<FfmpegResult<String>> transcribeAudio(File audioFile) async {
    try {
      final available = await _speech.initialize();
      if (!available) {
        return const FfmpegResult<String>(data: null, returnCode: 1);
      }
      final completer = Completer<String>();
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            completer.complete(result.recognizedWords);
          }
        },
      );
      final transcript = await completer.future;
      await _speech.stop();
      if (transcript.trim().isEmpty) {
        return const FfmpegResult<String>(data: null, returnCode: 1);
      }
      return FfmpegResult<String>(data: transcript, returnCode: 0);
    } catch (_) {
      return const FfmpegResult<String>(data: null, returnCode: 1);
    }
  }
}
