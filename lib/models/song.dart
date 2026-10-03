class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String artworkUrl;
  final String audioUrl;
  final int durationSeconds;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.artworkUrl,
    required this.audioUrl,
    required this.durationSeconds,
  });

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
      durationSeconds: map['duration'] ?? 30,
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
      durationSeconds: json['durationSeconds'] ?? 30,
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
    };
  }
}
