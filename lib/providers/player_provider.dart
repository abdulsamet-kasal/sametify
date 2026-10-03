import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../services/music_service.dart';

// Player State
class PlayerStateModel {
  final Song? currentSong;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final List<Song> queue;
  final int currentIndex;
  final bool isShuffle;
  final bool isRepeat;

  PlayerStateModel({
    this.currentSong,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = -1,
    this.isShuffle = false,
    this.isRepeat = false,
  });

  PlayerStateModel copyWith({
    Song? currentSong,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    List<Song>? queue,
    int? currentIndex,
    bool? isShuffle,
    bool? isRepeat,
  }) {
    return PlayerStateModel(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffle: isShuffle ?? this.isShuffle,
      isRepeat: isRepeat ?? this.isRepeat,
    );
  }
}

class AudioPlayerNotifier extends Notifier<PlayerStateModel> {
  late final AudioPlayer _audioPlayer;

  @override
  PlayerStateModel build() {
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((stateChanged) {
      state = state.copyWith(isPlaying: stateChanged == PlayerState.playing);
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      state = state.copyWith(duration: dur);
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
      duration: Duration(seconds: song.durationSeconds),
    );

    if (song.audioUrl.isNotEmpty) {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(song.audioUrl));
      } catch (e) {
        // error handling
      }
    }
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
      nextIndex = 0; // loop back
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
