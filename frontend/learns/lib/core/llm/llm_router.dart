// core/llm/llm_router.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

abstract class LLMProvider {
  String get id; // 'offline' | 'backend'
  Stream<String> stream(String prompt, {int maxTokens = 256, double temperature = .2});
}

Future<bool> hasInternet() async {
  final c = await Connectivity().checkConnectivity();
  return c != ConnectivityResult.none;
}

LLMProvider pickProvider({
  required bool offlinePref,
  required bool hasNet,
  required LLMProvider local,
  required LLMProvider backend,
}) =>
    offlinePref ? local : (hasNet ? backend : local);

/// Regla:
/// - offlinePref == true  -> local
/// - offlinePref == false -> backend si hay red; si no, local
class LLMRouter {
  final bool Function() offlinePref;   // función que devuelve el flag actual
  final LLMProvider local;
  final LLMProvider backend;

  LLMRouter({
    required this.offlinePref,
    required this.local,
    required this.backend,
  });

  Future<LLMProvider> _choose() async {
    if (offlinePref()) return local;
    final net = await hasInternet();
    return net ? backend : local;
  }

  Stream<String> stream(String prompt, {int maxTokens = 256, double temperature = .2}) async* {
    final p = await _choose();
    debugPrint('[LLMRouter] provider=${p.id}');
    yield* p.stream(prompt, maxTokens: maxTokens, temperature: temperature);
  }

  Future<String> mode() async => (await _choose()).id; // 'offline' | 'backend'
}
