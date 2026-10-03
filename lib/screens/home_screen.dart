import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import '../widgets/song_action_bottom_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(chartTracksProvider);
    final history = ref.watch(historyProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: false,
            expandedHeight: 70,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 16, bottom: 12),
              title: Text(
                'Günaydın Samet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                tooltip: 'Son Çalınanlar',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Ayarlar',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Son Dinlenenler Yatay Liste (Varsa)
                  if (history.isNotEmpty) ...[
                    const Text(
                      'Son Çalınanlar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 190,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: history.length > 8 ? 8 : history.length,
                        itemBuilder: (context, index) {
                          final song = history[index];
                          return _buildSongCard(context, ref, song, history, index);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Bugünün En Çok Dinlenenleri
                  const Text(
                    'Bugünün En Çok Dinlenenleri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  chartAsync.when(
                    data: (songs) {
                      if (songs.isEmpty) {
                        return const Center(child: Text('Şarkı bulunamadı'));
                      }
                      return SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: songs.length > 10 ? 10 : songs.length,
                          itemBuilder: (context, index) {
                            final song = songs[index];
                            return _buildSongCard(context, ref, song, songs, index);
                          },
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1DB954),
                        ),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Text('Hata: $err'),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Senin İçin Popüler Müzikler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  chartAsync.when(
                    data: (songs) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          return _buildSongTile(context, ref, song, songs, index);
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongCard(
    BuildContext context,
    WidgetRef ref,
    Song song,
    List<Song> queue,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(playerProvider.notifier).playSong(song, queue: queue, index: index);
      },
      child: Container(
        width: 135,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: song.artworkUrl,
                width: 135,
                height: 135,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 135,
                  height: 135,
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile(
    BuildContext context,
    WidgetRef ref,
    Song song,
    List<Song> queue,
    int index,
  ) {
    final playerState = ref.watch(playerProvider);
    final isCurrent = playerState.currentSong?.id == song.id;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: song.artworkUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            width: 50,
            height: 50,
            color: Colors.grey[800],
            child: const Icon(Icons.music_note, color: Colors.white),
          ),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isCurrent ? const Color(0xFF1DB954) : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 13,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, color: Colors.grey),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => SongActionBottomSheet(song: song),
          );
        },
      ),
      onTap: () {
        ref.read(playerProvider.notifier).playSong(song, queue: queue, index: index);
      },
    );
  }
}
