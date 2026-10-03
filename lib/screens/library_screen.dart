import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import 'playlist_detail_screen.dart';
import '../widgets/song_action_bottom_sheet.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final playlists = ref.watch(playlistsProvider);
    final downloads = ref.watch(downloadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kitaplığın',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1DB954),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Beğenilenler (${favorites.length})'),
            Tab(text: 'Listeler (${playlists.length})'),
            Tab(text: 'İndirilenler (${downloads.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            tooltip: 'Yeni Çalma Listesi Oluştur',
            onPressed: () {
              _showCreatePlaylistDialog(context);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Sekme: Beğenilen Şarkılar
          _buildFavoritesTab(favorites),

          // 2. Sekme: Çalma Listeleri
          _buildPlaylistsTab(playlists),

          // 3. Sekme: İndirilen Şarkılar (Çevrimdışı)
          _buildDownloadsTab(downloads),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab(List<Song> favorites) {
    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Beğendiğin şarkılar burada görünecek',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Beğenmek için şarkıların yanındaki kalp simgesine dokun.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final song = favorites[index];
        final playerState = ref.watch(playerProvider);
        final isCurrent = playerState.currentSong?.id == song.id;

        return Dismissible(
          key: Key('fav_${song.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.redAccent,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            ref.read(favoritesProvider.notifier).toggleFavorite(song);
          },
          child: ListTile(
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
            subtitle: Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SongActionBottomSheet(song: song),
                );
              },
            ),
            onTap: () {
              ref.read(playerProvider.notifier).playSong(
                    song,
                    queue: favorites,
                    index: index,
                  );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsTab(List<Playlist> playlists) {
    if (playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue_music,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'İlk çalma listeni oluştur',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.black,
              ),
              onPressed: () => _showCreatePlaylistDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Çalma Listesi Oluştur', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final firstSong = playlist.songs.isNotEmpty ? playlist.songs.first : null;

        return ListTile(
          leading: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(6),
            ),
            child: firstSong != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: firstSong.artworkUrl,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.music_note, color: Colors.white54),
          ),
          title: Text(
            playlist.name,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          subtitle: Text(
            'Çalma Listesi • ${playlist.songs.length} şarkı',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaylistDetailScreen(playlistId: playlist.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDownloadsTab(List<Song> downloads) {
    if (downloads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_done,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz indirilmiş şarkı yok',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Çevrimdışı dinlemek için herhangi bir şarkının veya listenin\nindirme simgesine dokun.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final song = downloads[index];
        final playerState = ref.watch(playerProvider);
        final isCurrent = playerState.currentSong?.id == song.id;

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
              const Icon(Icons.check_circle, color: Color(0xFF1DB954), size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${song.artist} • Çevrimdışı Hazır',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => SongActionBottomSheet(song: song),
              );
            },
          ),
          onTap: () {
            ref.read(playerProvider.notifier).playSong(
                  song,
                  queue: downloads,
                  index: index,
                );
          },
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Yeni Çalma Listesi', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Çalma listesi adı',
            hintStyle: TextStyle(color: Colors.white54),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1DB954)),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('İptal', style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954)),
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                ref.read(playlistsProvider.notifier).createPlaylist(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Oluştur', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
