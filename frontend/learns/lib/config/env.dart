class Env {
  // Backend base URL (injected at build time)
  static const apiBase = String.fromEnvironment('API_BASE', defaultValue: '');

  // Offline LLM switch: default OFF for public builds
  static const enableOfflineLLM =
      bool.fromEnvironment('ENABLE_OFFLINE_LLM', defaultValue: false);
}
