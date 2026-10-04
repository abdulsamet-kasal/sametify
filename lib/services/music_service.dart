import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song.dart';

class MusicService {
  static const String _baseUrl = 'https://api.deezer.com';
  static final YoutubeExplode _yt = YoutubeExplode();

  /// Deezer Popüler Listesi
  static Future<List<Song>> getChartTracks() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/chart/0/tracks?limit=30'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['data'] as List?) ?? [];
        return list.map((item) => Song.fromDeezer(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Deezer Şarkı & Sanatçı Arama
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
    } catch (_) {}
    return [];
  }

  /// Tam uzunlukta YouTube Audio Akış URL'si bulma
  static Future<String?> getFullAudioStreamUrl(Song song) async {
    try {
      final query = '${song.artist} - ${song.title} audio';
      final searchResults = await _yt.search.search(query);
      if (searchResults.isEmpty) return null;

      final video = searchResults.first;
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);
      
      if (manifest.audioOnly.isEmpty) {
        if(manifest.muxed.isNotEmpty){
           final bestMuxed = manifest.muxed.withHighestBitrate();
           return bestMuxed.url.toString();
        }
        return null;
      }

      final bestStream = manifest.audioOnly.withHighestBitrate();
      return bestStream.url.toString();
    } catch (e) {
      // Stream alma hatası yoksayıldı.
      return null; 
    }
  }

  /// Şarkıyı yerel cihaza mp3/m4a olarak indirme
  static Future<String?> downloadSong(Song song, {void Function(double progress)? onProgress}) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${docsDir.path}/downloads');
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      final fileName = '${song.id}_${song.title.replaceAll(RegExp(r'[^\w\s-]'), '')}.m4a';
      final file = File('${downloadsDir.path}/$fileName');
      if (file.existsSync()) {
        if (onProgress != null) onProgress(1.0);
        return file.path;
      }

      final query = '${song.artist} - ${song.title} audio';
      final searchResults = await _yt.search.search(query);
      if (searchResults.isEmpty) return null;

      final video = searchResults.first;
      final manifest = await _yt.videos.streamsClient.getManifest(video.id);
      
      StreamInfo? streamInfo;
      if (manifest.audioOnly.isNotEmpty) {
        streamInfo = manifest.audioOnly.withHighestBitrate();
      } else if (manifest.muxed.isNotEmpty) {
        streamInfo = manifest.muxed.withHighestBitrate();
      }

      if (streamInfo == null) return null;

      final stream = _yt.videos.streamsClient.get(streamInfo);

      final fileStream = file.openWrite();
      int count = 0;
      final total = streamInfo.size.totalBytes;

      await for (final data in stream) {
        count += data.length;
        if (total > 0 && onProgress != null) {
          onProgress(count / total);
        }
        fileStream.add(data);
      }
      await fileStream.flush();
      await fileStream.close();

      return file.path;
    } catch (e) {
      // İndirme hatası yoksayıldı.
      return null;
    }
  }
}
