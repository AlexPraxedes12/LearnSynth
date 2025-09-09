import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:learnsynth/services/offline_llm_compat.dart';
import '../../providers/settings_provider.dart';

typedef OnlineStreamFn = Stream<String> Function(
  String prompt, {int maxTokens, double temperature}
);

class OrchestratorLLM {
  final OnlineStreamFn onlineStream;
  final SettingsProvider settings;

  OrchestratorLLM({required this.onlineStream, required this.settings});

  Future<bool> _isOnline() async {
    final res = await Connectivity().checkConnectivity();
    return res.contains(ConnectivityResult.mobile) ||
        res.contains(ConnectivityResult.wifi) ||
        res.contains(ConnectivityResult.ethernet);
  }

  Stream<String> stream(String prompt,
      {int maxTokens = 256, double temperature = .2}) async* {
    final online = await _isOnline();
    final canOffline =
        settings.enableOfflineLLM && settings.offlineModelStatus == 'ready';
    if (!online && canOffline) {
      if (!OfflineLLM.instance.isReady) {
        await OfflineLLM.instance.init();
      }
      yield* OfflineLLM.instance.stream(prompt, maxTokens: maxTokens);
    } else {
      yield* onlineStream(prompt,
          maxTokens: maxTokens, temperature: temperature);
    }
  }
}

