import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Pop', 'color': Colors.redAccent, 'query': 'Pop'},
    {'title': 'Hip Hop', 'color': Colors.orangeAccent, 'query': 'Hip Hop'},
    {'title': 'Rock', 'color': Colors.deepOrange, 'query': 'Rock'},
    {'title': 'Türkçe Pop', 'color': Colors.green, 'query': 'Turkce Pop'},
    {'title': 'Türkçe Rap', 'color': Colors.purpleAccent, 'query': 'Turkce Rap'},
    {'title': 'Chill', 'color': Colors.blueAccent, 'query': 'Acoustic Chill'},
    {'title': 'Elektronik', 'color': Colors.teal, 'query': 'Electronic EDM'},
    {'title': 'Jazz & Blues', 'color': Colors.amber, 'query': 'Jazz'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ara'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Ne dinlemek istiyorsun?',
                  hintStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(Icons.search, color: Colors.black),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).state = val;
                },
              ),
            ),
            Expanded(
              child: query.isEmpty
                  ? _buildCategoriesGrid()
                  : _buildSearchResults(searchResults),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hepsine göz at',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              itemCount: _categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return GestureDetector(
                  onTap: () {
                    _searchController.text = cat['query'];
                    ref.read(searchQueryProvider.notifier).state = cat['query'];
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cat['color'],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      cat['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AsyncValue<List<Song>> resultsAsync) {
    return resultsAsync.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const Center(
            child: Text(
              'Sonuç bulunamadı.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
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
              subtitle: Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onPressed: () {},
              ),
              onTap: () {
                ref.read(playerProvider.notifier).playSong(song, queue: songs, index: index);
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1DB954),
        ),
      ),
      error: (err, stack) => Center(
        child: Text('Hata: $err', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}
