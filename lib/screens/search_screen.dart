import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../widgets/song_action_bottom_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = const [
    {'title': 'Pop', 'color': Color(0xFFE91E63), 'icon': Icons.music_note},
    {'title': 'Rock', 'color': Color(0xFFE65100), 'icon': Icons.album},
    {'title': 'Hip Hop / Rap', 'color': Color(0xFF673AB7), 'icon': Icons.mic},
    {'title': 'Türkçe Pop', 'color': Color(0xFF00897B), 'icon': Icons.star},
    {'title': 'Akustik & Chill', 'color': Color(0xFF1E88E5), 'icon': Icons.spa},
    {'title': 'Elektronik', 'color': Color(0xFF00ACC1), 'icon': Icons.speaker},
    {'title': 'Klasik & Caz', 'color': Color(0xFF8D6E63), 'icon': Icons.piano},
    {'title': 'Workout & Spor', 'color': Color(0xFFD81B60), 'icon': Icons.fitness_center},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final isSearching = ref.watch(searchQueryProvider).isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Ara',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              // Modern Spotify-style Arama Barı
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  hintText: 'Ne dinlemek istiyorsun?',
                  hintStyle: const TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search, color: Colors.black87),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black87),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),

              // Arama Sonuçları ya da Kategoriler
              Expanded(
                child: isSearching
                    ? searchResultsAsync.when(
                        data: (songs) {
                          if (songs.isEmpty) {
                            return const Center(
                              child: Text(
                                'Aramanızla eşleşen parça bulunamadı',
                                style: TextStyle(color: Colors.white60),
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
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
                                    width: 48,
                                    height: 48,
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
                                        queue: songs,
                                        index: index,
                                      );
                                },
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
                        ),
                        error: (err, _) => Center(
                          child: Text('Hata: $err', style: const TextStyle(color: Colors.redAccent)),
                        ),
                      )
                    : Column(
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
                              padding: const EdgeInsets.only(bottom: 80),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.6,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                return GestureDetector(
                                  onTap: () {
                                    final catName = cat['title'] as String;
                                    _searchController.text = catName;
                                    ref.read(searchQueryProvider.notifier).state = catName;
                                    setState(() {});
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cat['color'] as Color,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Stack(
                                      children: [
                                        Text(
                                          cat['title'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Positioned(
                                          right: -4,
                                          bottom: -4,
                                          child: Transform.rotate(
                                            angle: 0.3,
                                            child: Icon(
                                              cat['icon'] as IconData,
                                              size: 42,
                                              color: Colors.white.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
