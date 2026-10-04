import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../services/music_service.dart';

// Player State
class PlayerStateModel {
  final Song? currentSong;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final List<Song> queue;
  final int currentIndex;
  final bool isShuffle;
  final bool isRepeat;
  final String? errorMsg;

  PlayerStateModel({
    this.currentSong,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = -1,
    this.isShuffle = false,
    this.isRepeat = false,
    this.errorMsg,
  });

  PlayerStateModel copyWith({
    Song? currentSong,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    List<Song>? queue,
    int? currentIndex,
    bool? isShuffle,
    bool? isRepeat,
    String? errorMsg,
  }) {
    return PlayerStateModel(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffle: isShuffle ?? this.isShuffle,
      isRepeat: isRepeat ?? this.isRepeat,
      errorMsg: errorMsg,
    );
  }
}

class AudioPlayerNotifier extends Notifier<PlayerStateModel> {
  late final AudioPlayer _audioPlayer;

  @override
  PlayerStateModel build() {
    _audioPlayer = AudioPlayer();

    // Ses yönetimi optimize et
    _audioPlayer.setReleaseMode(ReleaseMode.stop);

    _audioPlayer.onPlayerStateChanged.listen((stateChanged) {
      state = state.copyWith(
        isPlaying: stateChanged == PlayerState.playing,
        isLoading: false,
      );
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      if (dur > Duration.zero) {
        state = state.copyWith(duration: dur);
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (state.isRepeat) {
        seek(Duration.zero);
        resume();
      } else {
        next();
      }
    });

    ref.onDispose(() {
      _audioPlayer.dispose();
    });

    return PlayerStateModel();
  }

  Future<void> playSong(Song song, {List<Song>? queue, int? index}) async {
    final newQueue = queue ?? [song];
    final newIndex = index ?? newQueue.indexWhere((s) => s.id == song.id);

    state = state.copyWith(
      currentSong: song,
      queue: newQueue,
      currentIndex: newIndex >= 0 ? newIndex : 0,
      position: Duration.zero,
      // Eğer YouTube'dan alınırsa duration tekrar güncellenecek
      duration: Duration(seconds: song.durationSeconds),
      isLoading: true,
      errorMsg: null,
    );

    try {
      await _audioPlayer.stop();

      // 1. Önce indirilen yerel dosya var mı kontrol et
      final downloadedSongs = ref.read(downloadsProvider);
      final localMatch = downloadedSongs.where((s) => s.id == song.id).firstOrNull;
      if (localMatch != null && localMatch.isDownloaded) {
        await _audioPlayer.play(DeviceFileSource(localMatch.localFilePath!));
        state = state.copyWith(isLoading: false);
        _saveToHistory(song);
        return;
      }

      // 2. Tam sürüm YouTube akış URL'sini çek
      final streamUrl = await MusicService.getFullAudioStreamUrl(song);
      if (streamUrl != null && streamUrl.isNotEmpty) {
        await _audioPlayer.play(UrlSource(streamUrl));
        state = state.copyWith(isLoading: false);
        _saveToHistory(song);
        return;
      }

      // 3. Youtube'dan akış alınamadıysa fallback Deezer preview (İsteğe bağlı, istenirse hata verilebilir)
      if (song.audioUrl.isNotEmpty) {
        await _audioPlayer.play(UrlSource(song.audioUrl));
        state = state.copyWith(isLoading: false, errorMsg: "Tam sürüm bulunamadı, önizleme oynatılıyor");
        _saveToHistory(song);
      } else {
        state = state.copyWith(isLoading: false, errorMsg: "Oynatılabilir kaynak bulunamadı.");
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMsg: "Şarkı çalınırken hata oluştu.");
    }
  }

  void _saveToHistory(Song song) {
    ref.read(historyProvider.notifier).addToHistory(song);
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> next() async {
    if (state.queue.isEmpty) return;
    int nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.queue.length) {
      nextIndex = 0;
    }
    await playSong(state.queue[nextIndex], queue: state.queue, index: nextIndex);
  }

  Future<void> previous() async {
    if (state.queue.isEmpty) return;
    if (state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    int prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) {
      prevIndex = state.queue.length - 1;
    }
    await playSong(state.queue[prevIndex], queue: state.queue, index: prevIndex);
  }

  void toggleShuffle() {
    state = state.copyWith(isShuffle: !state.isShuffle);
  }

  void toggleRepeat() {
    state = state.copyWith(isRepeat: !state.isRepeat);
  }
}

final playerProvider = NotifierProvider<AudioPlayerNotifier, PlayerStateModel>(() {
  return AudioPlayerNotifier();
});

// Chart Tracks Provider
final chartTracksProvider = FutureProvider<List<Song>>((ref) async {
  return MusicService.getChartTracks();
});

// Search Query & Search Results Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Song>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  return MusicService.searchTracks(query);
});

// Favorites Provider
class FavoritesNotifier extends Notifier<List<Song>> {
  static const _key = 'sametify_favorites';

  @override
  List<Song> build() {
    _loadFavorites();
    return [];
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key);
    if (jsonList != null) {
      state = jsonList.map((e) => Song.fromJson(jsonDecode(e))).toList();
    }
  }

  Future<void> toggleFavorite(Song song) async {
    final exists = state.any((s) => s.id == song.id);
    List<Song> updated;
    if (exists) {
      updated = state.where((s) => s.id != song.id).toList();
    } else {
      updated = [song, ...state];
    }
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    final stringList = updated.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_key, stringList);
  }

  bool isFavorite(String songId) {
    return state.any((s) => s.id == songId);
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<Song>>(() {
  return FavoritesNotifier();
});

// Playlists Provider
class PlaylistsNotifier extends Notifier<List<Playlist>> {
  static const _key = 'sametify_playlists';

  @override
  List<Playlist> build() {
    _loadPlaylists();
    return [];
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key);
    if (list != null) {
      state = list.map((e) => Playlist.fromJson(jsonDecode(e))).toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = state.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(_key, list);
  }

  Future<void> createPlaylist(String name, {String description = ''}) async {
    final newPlaylist = Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      songs: [],
      createdAt: DateTime.now(),
    );
    state = [...state, newPlaylist];
    await _save();
  }

  Future<void> deletePlaylist(String playlistId) async {
    state = state.where((p) => p.id != playlistId).toList();
    await _save();
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    state = state.map((p) {
      if (p.id == playlistId) {
        if (p.songs.any((s) => s.id == song.id)) return p;
        return p.copyWith(songs: [...p.songs, song]);
      }
      return p;
    }).toList();
    await _save();
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    state = state.map((p) {
      if (p.id == playlistId) {
        return p.copyWith(songs: p.songs.where((s) => s.id != songId).toList());
      }
      return p;
    }).toList();
    await _save();
  }
}

final playlistsProvider = NotifierProvider<PlaylistsNotifier, List<Playlist>>(() {
  return PlaylistsNotifier();
});

// Downloads Provider
class DownloadsNotifier extends Notifier<List<Song>> {
  static const _key = 'sametify_downloads';

  @override
  List<Song> build() {
    _loadDownloads();
    return [];
  }

  Future<void> _loadDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key);
    if (list != null) {
      final songs = list.map((e) => Song.fromJson(jsonDecode(e))).toList();
      state = songs.where((s) => s.isDownloaded).toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = state.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_key, list);
  }

  bool isDownloaded(String songId) {
    return state.any((s) => s.id == songId && s.isDownloaded);
  }

  Future<bool> downloadSingleSong(Song song, {void Function(double)? onProgress}) async {
    if (isDownloaded(song.id)) return true;

    final path = await MusicService.downloadSong(song, onProgress: onProgress);
    if (path != null) {
      final downloadedSong = song.copyWith(localFilePath: path);
      state = [downloadedSong, ...state.where((s) => s.id != song.id)];
      await _save();
      return true;
    }
    return false;
  }

  Future<void> downloadPlaylist(Playlist playlist, {void Function(int current, int total)? onProgress}) async {
    int count = 0;
    for (final song in playlist.songs) {
      await downloadSingleSong(song);
      count++;
      if (onProgress != null) onProgress(count, playlist.songs.length);
    }
  }

  Future<void> removeDownload(String songId) async {
    final song = state.where((s) => s.id == songId).firstOrNull;
    if (song != null && song.localFilePath != null) {
      final file = File(song.localFilePath!);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }
    state = state.where((s) => s.id != songId).toList();
    await _save();
  }
}

final downloadsProvider = NotifierProvider<DownloadsNotifier, List<Song>>(() {
  return DownloadsNotifier();
});

// Recently Played History Provider
class HistoryNotifier extends Notifier<List<Song>> {
  static const _key = 'sametify_history';

  @override
  List<Song> build() {
    _loadHistory();
    return [];
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key);
    if (list != null) {
      state = list.map((e) => Song.fromJson(jsonDecode(e))).toList();
    }
  }

  Future<void> addToHistory(Song song) async {
    final filtered = state.where((s) => s.id != song.id).toList();
    state = [song, ...filtered].take(50).toList();
    final prefs = await SharedPreferences.getInstance();
    final list = state.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_key, list);
  }

  Future<void> clearHistory() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, List<Song>>(() {
  return HistoryNotifier();
});
