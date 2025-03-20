import 'package:youtube_explode_dart/youtube_explode_dart.dart' show YoutubeExplode, Container;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class YouTubeService {
  final YoutubeExplode yt = YoutubeExplode();
  bool _isInitialized = false;
  
  // Add caching
  final Map<String, String> _audioUrlCache = {};
  final Map<String, Map<String, dynamic>> _videoDetailsCache = {};

  // Sleep therapy music categories
  static const Map<String, List<String>> sleepMusicCategories = {
    'Lofi': [
      'lofi sleep music for young adults',
      'lofi beats for insomnia relief',
      'calm lofi study music for sleep',
      'lofi hip hop radio for sleep',
    ],
    'Jazz': [
      'smooth jazz for sleep therapy',
      'relaxing jazz piano for insomnia',
      'jazz sleep music for young adults',
      'soft jazz for deep sleep',
    ],
    'Classical': [
      'classical music for sleep therapy',
      'peaceful piano for insomnia relief',
      'classical sleep music for young adults',
      'relaxing classical for deep sleep',
    ],
    'Nature': [
      'rain sounds for sleep therapy',
      'ocean waves for insomnia relief',
      'forest sounds for deep sleep',
      'nature sounds for young adults sleep',
    ],
    'Ambient': [
      'ambient sleep music therapy',
      'sleep meditation music for young adults',
      'binaural beats for insomnia relief',
      'ambient music for deep sleep',
    ],
    'White Noise': [
      'white noise for sleep therapy',
      'brown noise for insomnia relief',
      'sleep therapy sounds for young adults',
      'pink noise for deep sleep',
    ],
  };

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isInitialized = true;
    } catch (e) {
      print('Error initializing YouTube service: $e');
      rethrow;
    }
  }

  String _getTherapeuticSearchQuery(String mood, List<String> genres) {
    // Combine mood and genres to find the most appropriate sleep music
    String baseQuery = '';
    
    // Map moods to appropriate music types with age-specific terms
    switch (mood.toLowerCase()) {
      case 'anxious':
        baseQuery = 'calming sleep music for anxiety relief';
        break;
      case 'stressed':
        baseQuery = 'stress relief sleep music therapy';
        break;
      case 'restless':
        baseQuery = 'deep sleep music for insomnia relief';
        break;
      default:
        baseQuery = 'relaxing sleep music for young adults';
    }

    // Add genre-specific terms
    for (var genre in genres) {
      if (sleepMusicCategories.containsKey(genre)) {
        // Randomly select a query from the category
        final queries = sleepMusicCategories[genre]!;
        baseQuery = queries[DateTime.now().millisecondsSinceEpoch % queries.length];
        break;
      }
    }

    // Add additional filters for better results
    return '$baseQuery for sleep therapy insomnia relief';
  }

  Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    if (!_isInitialized) await initialize();
    
    try {
      final parts = query.split('-');
      String searchQuery = parts.length > 1 
          ? '${parts[1].trim()} ${parts[0].trim()} sleep music therapy for young adults'
          : '$query sleep music therapy for young adults';

      print('Searching YouTube with query: $searchQuery');

      var searchResults = await yt.search.search(searchQuery);
      var videos = <Map<String, dynamic>>[];
      
      // Process only first 5 results
      for (var video in searchResults.take(5)) {
        // Check cache first
        if (_videoDetailsCache.containsKey(video.id.value)) {
          videos.add(_videoDetailsCache[video.id.value]!);
          continue;
        }

        try {
          var videoDetails = await yt.videos.get(video.id);
          
          // Filter out videos that are too long (more than 1 hour) or too short (less than 5 minutes)
          if (videoDetails.duration != null) {
            final duration = videoDetails.duration!;
            if (duration.inMinutes < 5 || duration.inHours > 1) {
              continue;
            }
          }

          final videoData = {
            'id': video.id.value,
            'title': video.title,
            'artist': parts.length > 1 ? parts[0].trim() : video.author,
            'thumbnailUrl': video.thumbnails.highResUrl,
            'url': 'https://youtube.com/watch?v=${video.id.value}',
            'duration': videoDetails.duration?.toString() ?? 'Unknown',
            'viewCount': videoDetails.engagement.viewCount,
          };
          
          // Cache the video details
          _videoDetailsCache[video.id.value] = videoData;
          videos.add(videoData);
        } catch (e) {
          print('Error getting video details: $e');
        }
      }

      videos.sort((a, b) => ((b['viewCount'] ?? 0) as int).compareTo((a['viewCount'] ?? 0) as int));
      return videos;
    } catch (e) {
      print('Error searching videos: $e');
      rethrow;
    }
  }

  Future<void> playTrack(String videoId) async {
    if (!_isInitialized) await initialize();
    
    try {
      final url = Uri.parse('https://youtube.com/watch?v=$videoId');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch YouTube video';
      }
    } catch (e) {
      print('Error playing video: $e');
      rethrow;
    }
  }

  Future<String> getAudioUrl(String videoId) async {
    try {
      print('Fetching manifest for video $videoId');
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      
      if (manifest.audioOnly.isEmpty) {
        throw Exception('No audio streams available for video $videoId');
      }

      // Sort all streams by size to prioritize smaller files
      var allStreams = manifest.audioOnly.toList()
        ..sort((a, b) => a.size.totalBytes.compareTo(b.size.totalBytes));

      print('Available audio streams:');
      for (var stream in allStreams) {
        print('- Container: ${stream.container.name}');
        print('  Bitrate: ${stream.bitrate.bitsPerSecond / 1000}kbps');
        print('  Size: ${stream.size.totalBytes / 1024 / 1024}MB');
      }

      // First try: Look for small M4A streams
      var m4aStreams = allStreams
          .where((s) => s.container.name.toLowerCase() == 'm4a' && 
                       s.size.totalBytes < 10 * 1024 * 1024) // Less than 10MB
          .toList();

      // Second try: Look for small MP4 streams
      var mp4Streams = allStreams
          .where((s) => s.container.name.toLowerCase() == 'mp4' &&
                       s.size.totalBytes < 10 * 1024 * 1024)
          .toList();

      // Select the best available stream prioritizing size and format
      var audioStream = m4aStreams.firstWhere(
        (s) => s.bitrate.bitsPerSecond >= 64000 && s.bitrate.bitsPerSecond <= 128000,
        orElse: () => mp4Streams.firstWhere(
          (s) => s.bitrate.bitsPerSecond >= 64000 && s.bitrate.bitsPerSecond <= 128000,
          orElse: () => allStreams.firstWhere(
            (s) => s.size.totalBytes < 15 * 1024 * 1024, // Max 15MB
            orElse: () => allStreams.first,
          ),
        ),
      );

      final url = audioStream.url.toString();
      
      print('Selected stream details:');
      print('- Container: ${audioStream.container.name}');
      print('- Bitrate: ${audioStream.bitrate.bitsPerSecond / 1000}kbps');
      print('- Size: ${audioStream.size.totalBytes / 1024 / 1024}MB');
      print('- URL length: ${url.length}');
      
      return url;
    } catch (e) {
      print('Error getting audio URL for video $videoId: $e');
      rethrow;
    }
  }

  // Prefetch audio URLs for upcoming tracks
  Future<void> prefetchAudioUrls(List<String> videoIds) async {
    print('Prefetching audio URLs for ${videoIds.length} tracks');
    for (var videoId in videoIds) {
      if (!_audioUrlCache.containsKey(videoId)) {
        try {
          final url = await getAudioUrl(videoId);
          _audioUrlCache[videoId] = url;
          print('Successfully prefetched audio URL for $videoId');
        } catch (e) {
          print('Error prefetching audio URL for $videoId: $e');
        }
      }
    }
  }

  // Prepare next track with fresh URL
  Future<void> prepareNextTrack(String currentVideoId, List<String> playlist) async {
    final currentIndex = playlist.indexOf(currentVideoId);
    if (currentIndex < playlist.length - 1) {
      final nextVideoId = playlist[currentIndex + 1];
      try {
        // Always get a fresh URL for the next track
        final url = await getAudioUrl(nextVideoId);
        _audioUrlCache[nextVideoId] = url;
        print('Prepared next track: $nextVideoId');
      } catch (e) {
        print('Error preparing next track: $e');
      }
    }
  }

  void clearCache() {
    _audioUrlCache.clear();
    _videoDetailsCache.clear();
  }

  @override
  void dispose() {
    clearCache();
    yt.close();
  }
} 