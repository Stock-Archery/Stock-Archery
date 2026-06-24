import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'app_theme_mode';
const _kLanguageKey = 'app_language';

enum AppLanguage { english, hindi }

class SettingsState {
  final ThemeMode themeMode;
  final AppLanguage language;

  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.language = AppLanguage.english,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }
}

class SettingsViewModel extends StateNotifier<SettingsState> {
  SettingsViewModel() : super(const SettingsState()) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme
    final themeIndex = prefs.getInt(_kThemeKey) ?? 2; // default: system
    final themeMode = ThemeMode.values[themeIndex.clamp(0, 2)];

    // Load language
    final langIndex = prefs.getInt(_kLanguageKey) ?? 0;
    final language = AppLanguage.values[langIndex.clamp(0, 1)];

    state = state.copyWith(themeMode: themeMode, language: language);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeKey, mode.index);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    state = state.copyWith(language: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLanguageKey, lang.index);
  }
}

final settingsProvider = StateNotifierProvider<SettingsViewModel, SettingsState>((ref) {
  return SettingsViewModel();
});
