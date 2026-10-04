import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    final searchResults = await yt.search.search("Tarkan Yolla audio");
    if (searchResults.isEmpty) {
      print("No results");
      return;
    }
    final video = searchResults.first;
    print("Found video: ${video.title} (ID: ${video.id})");
    
    final manifest = await yt.videos.streamsClient.getManifest(video.id);
    if (manifest.audioOnly.isNotEmpty) {
      final bestStream = manifest.audioOnly.withHighestBitrate();
      print("Stream URL: ${bestStream.url}");
    } else {
      print("No audio only stream");
    }
  } catch (e) {
    print("Error: $e");
  } finally {
    yt.close();
  }
}
