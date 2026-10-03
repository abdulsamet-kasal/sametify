import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final String audioQuality;
  final bool offlineModeOnly;
  final bool autoPlay;
  final bool normalizeAudio;
  final double cacheSizeMb;

  SettingsState({
    this.audioQuality = 'Yüksek (320kbps)',
    this.offlineModeOnly = false,
    this.autoPlay = true,
    this.normalizeAudio = true,
    this.cacheSizeMb = 14.5,
  });

  SettingsState copyWith({
    String? audioQuality,
    bool? offlineModeOnly,
    bool? autoPlay,
    bool? normalizeAudio,
    double? cacheSizeMb,
  }) {
    return SettingsState(
      audioQuality: audioQuality ?? this.audioQuality,
      offlineModeOnly: offlineModeOnly ?? this.offlineModeOnly,
      autoPlay: autoPlay ?? this.autoPlay,
      normalizeAudio: normalizeAudio ?? this.normalizeAudio,
      cacheSizeMb: cacheSizeMb ?? this.cacheSizeMb,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _keyQuality = 'sametify_quality';
  static const _keyOffline = 'sametify_offline';
  static const _keyAutoplay = 'sametify_autoplay';

  @override
  SettingsState build() {
    _load();
    return SettingsState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      audioQuality: prefs.getString(_keyQuality) ?? 'Yüksek (320kbps)',
      offlineModeOnly: prefs.getBool(_keyOffline) ?? false,
      autoPlay: prefs.getBool(_keyAutoplay) ?? true,
    );
  }

  Future<void> setAudioQuality(String quality) async {
    state = state.copyWith(audioQuality: quality);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQuality, quality);
  }

  Future<void> toggleOfflineMode(bool val) async {
    state = state.copyWith(offlineModeOnly: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOffline, val);
  }

  Future<void> toggleAutoPlay(bool val) async {
    state = state.copyWith(autoPlay: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoplay, val);
  }

  Future<void> toggleNormalizeAudio(bool val) async {
    state = state.copyWith(normalizeAudio: val);
  }

  Future<void> clearCache() async {
    state = state.copyWith(cacheSizeMb: 0.0);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
