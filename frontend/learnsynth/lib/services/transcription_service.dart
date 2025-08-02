import 'dart:io';

/// A simple wrapper that mimics an FFmpeg session result.
class FfmpegResult<T> {
  final T? data;
  final int returnCode;

  const FfmpegResult({this.data, required this.returnCode});

  bool get isSuccess => returnCode == 0;
}

/// Provides audio transcription utilities.
///
/// Actual transcription and audio processing logic will be implemented in a
/// future revision. For now, these methods return placeholder values so the
/// rest of the application can be wired up.
class TranscriptionService {
  /// Transcribes the given [audioFile] and returns the recognized text along
  /// with a mock FFmpeg return code.
  Future<FfmpegResult<String>> transcribeAudio(File audioFile) async {
    await Future.delayed(const Duration(seconds: 1));
    return const FfmpegResult(data: 'Transcription placeholder', returnCode: 0);
  }

  /// Extracts the audio track from a [videoFile].
  ///
  /// The current stub simply returns the [videoFile] itself along with a mock
  /// return code. In a real implementation this would return a path to a newly
  /// generated audio file (for example, a WAV file).
  Future<FfmpegResult<File>> extractAudioFromVideo(File videoFile) async {
    await Future.delayed(const Duration(seconds: 1));
    return FfmpegResult(data: videoFile, returnCode: 0);
  }
}

