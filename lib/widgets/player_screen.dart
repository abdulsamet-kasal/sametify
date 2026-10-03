import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Çalan şarkı yok'),
        ),
      );
    }

    final isFav = ref.watch(favoritesProvider.notifier).isFavorite(song.id);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text(
              'ŞU ANDA ÇALINIYOR',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                color: Color(0xFFB3B3B3),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              song.album.isNotEmpty ? song.album : 'Sametify',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Cover Artwork
              Center(
                child: Hero(
                  tag: 'current_artwork',
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: song.artworkUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.music_note,
                              size: 100, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Title, Artist, Favorite
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          song.artist,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? const Color(0xFF1DB954) : Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      ref.read(favoritesProvider.notifier).toggleFavorite(song);
                    },
                  ),
                ],
              ),

              // Progress Bar
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      min: 0.0,
                      max: playerState.duration.inMilliseconds > 0
                          ? playerState.duration.inMilliseconds.toDouble()
                          : 1.0,
                      value: playerState.position.inMilliseconds
                          .clamp(0, playerState.duration.inMilliseconds)
                          .toDouble(),
                      onChanged: (val) {
                        ref
                            .read(playerProvider.notifier)
                            .seek(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(playerState.position),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          _formatDuration(playerState.duration),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Playback Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: playerState.isShuffle
                          ? const Color(0xFF1DB954)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      ref.read(playerProvider.notifier).toggleShuffle();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous,
                        size: 38, color: Colors.white),
                    onPressed: () {
                      ref.read(playerProvider.notifier).previous();
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(playerProvider.notifier).togglePlayPause();
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        playerState.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 38,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next,
                        size: 38, color: Colors.white),
                    onPressed: () {
                      ref.read(playerProvider.notifier).next();
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.repeat,
                      color: playerState.isRepeat
                          ? const Color(0xFF1DB954)
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      ref.read(playerProvider.notifier).toggleRepeat();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
