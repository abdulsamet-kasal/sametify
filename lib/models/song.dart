import 'dart:io';

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String artworkUrl;
  final String audioUrl; // Preview or YouTube streaming URL
  final int durationSeconds;
  final String? localFilePath; // If downloaded locally

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.artworkUrl,
    required this.audioUrl,
    required this.durationSeconds,
    this.localFilePath,
  });

  bool get isDownloaded =>
      localFilePath != null &&
      localFilePath!.isNotEmpty &&
      File(localFilePath!).existsSync();

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? artworkUrl,
    String? audioUrl,
    int? durationSeconds,
    String? localFilePath,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }

  factory Song.fromDeezer(Map<String, dynamic> map) {
    final artistMap = map['artist'] as Map<String, dynamic>?;
    final albumMap = map['album'] as Map<String, dynamic>?;

    return Song(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? 'Bilinmeyen Şarkı',
      artist: artistMap?['name'] ?? 'Bilinmeyen Sanatçı',
      album: albumMap?['title'] ?? '',
      artworkUrl: albumMap?['cover_medium'] ??
          artistMap?['picture_medium'] ??
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500',
      audioUrl: map['preview'] ?? '',
      durationSeconds: map['duration'] ?? 180,
    );
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      album: json['album'] ?? '',
      artworkUrl: json['artworkUrl'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      durationSeconds: json['durationSeconds'] ?? 180,
      localFilePath: json['localFilePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'artworkUrl': artworkUrl,
      'audioUrl': audioUrl,
      'durationSeconds': durationSeconds,
      'localFilePath': localFilePath,
    };
  }
}

class Playlist {
  final String id;
  final String name;
  final String description;
  final List<Song> songs;
  final DateTime createdAt;

  const Playlist({
    required this.id,
    required this.name,
    this.description = '',
    this.songs = const [],
    required this.createdAt,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    List<Song>? songs,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      songs: (json['songs'] as List<dynamic>? ?? [])
          .map((s) => Song.fromJson(s as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'songs': songs.map((s) => s.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
