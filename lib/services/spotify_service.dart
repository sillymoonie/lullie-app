import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify/spotify.dart';

class SpotifyService {
  late SpotifyApi spotify;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await SpotifySdk.connectToSpotifyRemote(
        clientId: dotenv.env['SPOTIFY_CLIENT_ID']!,
        redirectUrl: dotenv.env['SPOTIFY_REDIRECT_URL']!,
      );

      final credentials = SpotifyApiCredentials(
        dotenv.env['SPOTIFY_CLIENT_ID']!,
        dotenv.env['SPOTIFY_CLIENT_SECRET']!,
      );
      
      spotify = SpotifyApi(credentials);
      _isInitialized = true;
    } catch (e) {
      print('Error initializing Spotify: $e');
      rethrow;
    }
  }

  Future<List<Track>> searchTracks(String query) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Split the query into artist and title if it contains a hyphen
      final parts = query.split('-');
      String searchQuery;
      
      if (parts.length > 1) {
        final artist = parts[0].trim();
        final title = parts[1].trim();
        // Search with both artist and title for better accuracy
        searchQuery = '$title artist:$artist';
      } else {
        searchQuery = query.trim();
      }

      print('Searching Spotify with query: $searchQuery'); // Debug print

      var searchResult = await spotify.search.get(
        searchQuery,
        types: [SearchType.track],
      ).first();

      if (searchResult.isNotEmpty) {
        var tracks = searchResult.first as Page<Track>;
        var items = tracks.items ?? [];
        
        // If we have artist and title, try to find the best match
        if (parts.length > 1) {
          final artist = parts[0].trim().toLowerCase();
          final title = parts[1].trim().toLowerCase();
          
          print('Looking for exact match - Artist: $artist, Title: $title'); // Debug print
          
          // Try to find an exact match first
          var exactMatch = items.where((track) {
            final trackArtist = track.artists?.first.name?.toLowerCase() ?? '';
            final trackTitle = track.name?.toLowerCase() ?? '';
            return trackArtist.contains(artist) && trackTitle.contains(title);
          }).toList();
          
          if (exactMatch.isNotEmpty) {
            print('Found exact match: ${exactMatch.first.name} by ${exactMatch.first.artists?.first.name}'); // Debug print
            return [exactMatch.first];
          }
        }
        
        // If no exact match or no artist-title split, return the first result
        if (items.isNotEmpty) {
          print('Using first result: ${items.first.name} by ${items.first.artists?.first.name}'); // Debug print
          return [items.first];
        }
      }
      
      print('No tracks found for query: $searchQuery'); // Debug print
      return [];
    } catch (e) {
      print('Error searching tracks: $e');
      rethrow;
    }
  }

  Future<void> playTrack(String spotifyUri) async {
    if (!_isInitialized) await initialize();
    
    try {
      await SpotifySdk.play(spotifyUri: spotifyUri);
    } catch (e) {
      print('Error playing track: $e');
      rethrow;
    }
  }

  Future<void> pausePlayback() async {
    if (!_isInitialized) await initialize();
    
    try {
      await SpotifySdk.pause();
    } catch (e) {
      print('Error pausing playback: $e');
      rethrow;
    }
  }
} 