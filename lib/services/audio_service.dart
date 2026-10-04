import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song_model.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer get player => _audioPlayer;

  final List<SongModel> _currentPlaylist = [];
  int _currentIndex = 0;
  
  ConcatenatingAudioSource? _playlist;

  Future<void> playSong(SongModel song) async {
    try {
      final audioSource = AudioSource.uri(
        Uri.parse(song.url),
        tag: MediaItem(
          id: song.id,
          album: song.artist,
          title: song.title,
          artUri: Uri.parse(song.imageUrl),
        ),
      );
      
      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  Future<void> playPlaylist(List<SongModel> songs, {int initialIndex = 0}) async {
    _currentPlaylist.clear();
    _currentPlaylist.addAll(songs);
    _currentIndex = initialIndex;

    final children = songs.map((song) => AudioSource.uri(
      Uri.parse(song.url),
      tag: MediaItem(
        id: song.id,
        album: song.artist,
        title: song.title,
        artUri: Uri.parse(song.imageUrl),
      ),
    )).toList();

    _playlist = ConcatenatingAudioSource(children: children);
    
    await _audioPlayer.setAudioSource(
      _playlist!,
      initialIndex: initialIndex,
      initialPosition: Duration.zero,
    );
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }
}
