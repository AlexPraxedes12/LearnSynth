import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class TranscriptionService {
  // Android emulator: 10.0.2.2 points to the host machine
  final Uri _endpoint = Uri.parse('http://10.0.2.2:8000/transcribe');

  Future<String> transcribeFile(File input) async {
    File? tmpWav;
    try {
      // 1) Convert to WAV 16kHz mono (strip video track if any)
      final tmpDir = await getTemporaryDirectory();
      final outPath = p.join(
        tmpDir.path,
        '${p.basenameWithoutExtension(input.path)}_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      tmpWav = File(outPath);

      final ext = p.extension(input.path).toLowerCase();
      final isVideo = ['.mp4', '.mkv', '.mov', '.avi', '.webm'].contains(ext);

      final cmd = isVideo
          ? '-i "${input.path}" -vn -ac 1 -ar 16000 -sample_fmt s16 -f wav "$outPath"'
          : '-i "${input.path}" -ac 1 -ar 16000 -sample_fmt s16 -f wav "$outPath"';

      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();
      if (rc == null || !ReturnCode.isSuccess(rc)) {
        final logs = await session.getAllLogsAsString();
        throw 'FFmpeg failed (rc=$rc). $logs';
      }
      if (!await tmpWav.exists()) throw 'WAV not created';

      // 2) Upload to backend
      final req = http.MultipartRequest('POST', _endpoint)
        ..files.add(await http.MultipartFile.fromPath('file', tmpWav.path));

      final streamed = await req.send().timeout(const Duration(minutes: 2));
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode != 200) {
        throw 'HTTP ${streamed.statusCode}: $body';
      }

      // 3) Parse transcript
      final map = jsonDecode(body) as Map<String, dynamic>;
      final text = (map['text'] ?? map['transcript'] ?? map['result'] ?? '').toString();
      if (text.trim().isEmpty) throw 'Empty transcript';
      return text;
    } catch (e, st) {
      debugPrint('TranscriptionService error: $e\n$st');
      return 'Error: $e';
    } finally {
      if (tmpWav != null && await tmpWav.exists()) {
        await tmpWav.delete();
      }
    }
  }
}
