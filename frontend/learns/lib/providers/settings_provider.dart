import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/net/api_config.dart';
import '../config/env.dart';

class SettingsProvider extends ChangeNotifier {
  static const _themeKey = 'themeMode';
  static const _localeKey = 'locale';
  static const _offlineKey = 'enableOfflineLLM';
  static const _timeoutKey = 'backendTimeout';

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  bool _enableOfflineLLM = false;
  Duration _backendTimeout = ApiConfig.backendTimeout;
  String offlineModelStatus = 'not_installed';
  String? offlineError;
  SharedPreferences? _prefs;

  SettingsProvider() {
    _load();
  }

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get enableOfflineLLM => Env.enableOfflineLLM && _enableOfflineLLM;
  Duration get backendTimeout => _backendTimeout;

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final themeStr = _prefs!.getString(_themeKey);
    if (themeStr != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == themeStr,
        orElse: () => ThemeMode.system,
      );
    }
    final localeStr = _prefs!.getString(_localeKey);
    if (localeStr != null) {
      _locale = Locale(localeStr);
    }
    if (Env.enableOfflineLLM) {
      _enableOfflineLLM = _prefs!.getBool(_offlineKey) ?? false;
    } else {
      _enableOfflineLLM = false;
    }
    final timeoutSecs = _prefs!.getInt(_timeoutKey);
    if (timeoutSecs != null) {
      _backendTimeout = Duration(seconds: timeoutSecs);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setString(_themeKey, mode.name);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _prefs?.setString(_localeKey, locale.languageCode);
    notifyListeners();
  }

  Future<void> setEnableOfflineLLM(bool value) async {
    if (!Env.enableOfflineLLM) return;
    _enableOfflineLLM = value;
    await _prefs?.setBool(_offlineKey, value);
    notifyListeners();
  }

  Future<void> setBackendTimeout(Duration d) async {
    _backendTimeout = d;
    await _prefs?.setInt(_timeoutKey, d.inSeconds);
    notifyListeners();
  }

  void setOfflineStatus(String s, {String? error}) {
    if (!Env.enableOfflineLLM) return;
    offlineModelStatus = s;
    offlineError = error;
    notifyListeners();
  }
}
