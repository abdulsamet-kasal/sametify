import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final playlist = playlists.where((p) => p.id == playlistId).firstOrNull;

    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Çalma listesi bulunamadı')),
      );
    }

    final downloads = ref.watch(downloadsProvider);
    final isAllDownloaded = playlist.songs.isNotEmpty &&
        playlist.songs.every((s) => downloads.any((d) => d.id == s.id && d.isDownloaded));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                playlist.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3E1E68), Color(0xFF121212)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  _showDeleteConfirm(context, ref, playlist);
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Text(
                    '${playlist.songs.length} şarkı',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  // Toplu İndir Butonu
                  IconButton(
                    icon: Icon(
                      isAllDownloaded ? Icons.download_done : Icons.download_for_offline_outlined,
                      color: isAllDownloaded ? const Color(0xFF1DB954) : Colors.white,
                      size: 28,
                    ),
                    onPressed: () async {
                      if (playlist.songs.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('İndirilecek şarkı yok')),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Çalma listesi indirilmeye başlandı...')),
                      );
                      await ref.read(downloadsProvider.notifier).downloadPlaylist(playlist);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tüm liste çevrimdışı kullanım için indirildi!')),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  // Oynat Butonu
                  FloatingActionButton.small(
                    backgroundColor: const Color(0xFF1DB954),
                    heroTag: 'play_playlist_fab',
                    onPressed: playlist.songs.isEmpty
                        ? null
                        : () {
                            ref.read(playerProvider.notifier).playSong(
                                  playlist.songs.first,
                                  queue: playlist.songs,
                                  index: 0,
                                );
                          },
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
                  ),
                ],
              ),
            ),
          ),
          playlist.songs.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.playlist_add,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Bu listede henüz şarkı yok',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Arama bölümünden şarkı ekleyebilirsin.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = playlist.songs[index];
                      final playerState = ref.watch(playerProvider);
                      final isCurrent = playerState.currentSong?.id == song.id;
                      final isDownloaded = downloads.any((d) => d.id == song.id && d.isDownloaded);

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: song.artworkUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
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
                        subtitle: Row(
                          children: [
                            if (isDownloaded) ...[
                              const Icon(Icons.download_done, color: Color(0xFF1DB954), size: 14),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
                          onPressed: () {
                            ref.read(playlistsProvider.notifier).removeSongFromPlaylist(playlist.id, song.id);
                          },
                        ),
                        onTap: () {
                          ref.read(playerProvider.notifier).playSong(
                                song,
                                queue: playlist.songs,
                                index: index,
                              );
                        },
                      );
                    },
                    childCount: playlist.songs.length,
                  ),
                ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, Playlist playlist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Çalma Listesini Sil'),
        content: Text('"${playlist.name}" listesini silmek istediğinden emin misin?'),
        actions: [
          TextButton(
            child: const Text('İptal', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(playlistsProvider.notifier).deletePlaylist(playlist.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
