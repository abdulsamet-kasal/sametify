import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';

class SongActionBottomSheet extends ConsumerWidget {
  final Song song;

  const SongActionBottomSheet({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider.notifier).isFavorite(song.id);
    final isDownloaded = ref.watch(downloadsProvider.notifier).isDownloaded(song.id);
    final playlists = ref.watch(playlistsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF282828),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Şarkı Bilgisi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: song.artworkUrl,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, thickness: 1, height: 24),

            // Beğen / Beğenmekten Vazgeç
            ListTile(
              leading: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? const Color(0xFF1DB954) : Colors.white,
              ),
              title: Text(isFav ? 'Beğenilenlerden Kaldır' : 'Beğenilenlere Ekle'),
              onTap: () {
                ref.read(favoritesProvider.notifier).toggleFavorite(song);
                Navigator.pop(context);
              },
            ),

            // İndir / İndirilenlerden Sil
            ListTile(
              leading: Icon(
                isDownloaded ? Icons.download_done : Icons.download_rounded,
                color: isDownloaded ? const Color(0xFF1DB954) : Colors.white,
              ),
              title: Text(isDownloaded ? 'Cihazdan Sil' : 'Şarkıyı İndir (Çevrimdışı Dinle)'),
              subtitle: Text(
                isDownloaded ? 'Cihaz hafızasında kayıtlı' : 'Tam parça yüksek kalitede indirilir',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
              onTap: () async {
                Navigator.pop(context);
                if (isDownloaded) {
                  await ref.read(downloadsProvider.notifier).removeDownload(song.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('"${song.title}" indirilenlerden kaldırıldı')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${song.title}" indiriliyor...')),
                  );
                  final success = await ref.read(downloadsProvider.notifier).downloadSingleSong(song);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'İndirme tamamlandı! Artık internetsiz dinleyebilirsiniz.'
                              : 'İndirme başarısız oldu.',
                        ),
                      ),
                    );
                  }
                }
              },
            ),

            // Çalma Listesine Ekle
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.white),
              title: const Text('Çalma Listesine Ekle'),
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylistDialog(context, ref, playlists, song);
              },
            ),

            // Kuyruğa Ekle
            ListTile(
              leading: const Icon(Icons.queue_music, color: Colors.white),
              title: const Text('Kuyruğa Ekle'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sıradaki parça olarak eklendi')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    List<Playlist> playlists,
    Song song,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF242424),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Çalma Listesi Seç',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('Henüz hiç çalma listesi oluşturmadınız.',
                      style: TextStyle(color: Colors.white60)),
                )
              else
                ...playlists.map(
                  (p) => ListTile(
                    leading: const Icon(Icons.playlist_play, color: Color(0xFF1DB954)),
                    title: Text(p.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${p.songs.length} şarkı',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    onTap: () {
                      ref.read(playlistsProvider.notifier).addSongToPlaylist(p.id, song);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('"${p.name}" listesine eklendi')),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
