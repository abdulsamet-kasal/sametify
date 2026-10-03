import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class MusicService {
  static const String _baseUrl = 'https://api.deezer.com';

  static Future<List<Song>> getChartTracks() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/chart/0/tracks?limit=25'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List?) ?? [];
        return list.map((item) => Song.fromDeezer(item)).toList();
      }
    } catch (e) {
      // fallback
    }
    return [];
  }

  static Future<List<Song>> searchTracks(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final url = Uri.parse('$_baseUrl/search?q=${Uri.encodeComponent(query)}&limit=30');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List?) ?? [];
        return list.map((item) => Song.fromDeezer(item)).toList();
      }
    } catch (e) {
      // fallback
    }
    return [];
  }

  static Future<List<Song>> getGenreTracks(String genreQuery) async {
    return searchTracks(genreQuery);
  }
}
