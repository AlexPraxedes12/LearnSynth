import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

/// A simple wrapper that mimics an FFmpeg session result.
class FfmpegResult<T> {
  final T? data;
  final int returnCode;

  const FfmpegResult({this.data, required this.returnCode});

  bool get isSuccess => returnCode == 0;
}

/// Provides audio transcription utilities backed by on-device processing.
class TranscriptionService {
  final VoskFlutter _vosk = VoskFlutter();

  TranscriptionService() {
    unawaited(_vosk.init(modelPath: 'assets/models/vosk-model-small'));
  }

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
  /// The transcription is performed on-device using the Vosk speech recognition
  /// engine. A [FfmpegResult] containing the transcription text is returned
  /// on success, otherwise the [data] is `null` and [returnCode] is non-zero.
  Future<FfmpegResult<String>> transcribeAudio(File audioFile) async {
    try {
      final transcript = await _vosk.recognize(audioFile.path);
      if (transcript.trim().isEmpty) {
        return const FfmpegResult<String>(data: null, returnCode: 1);
      }
      return FfmpegResult<String>(data: transcript, returnCode: 0);
    } catch (_) {
      return const FfmpegResult<String>(data: null, returnCode: 1);
    }
  }
}
