import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:lullie_app/services/statistics_service.dart';

class AudioService extends ChangeNotifier {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal() {
    _initializeListeners();
  }

  final AudioPlayer audioPlayer = AudioPlayer();
  final StatisticsService _statisticsService = StatisticsService();
  
  Map<String, dynamic>? _currentTrack;
  List<Map<String, dynamic>> _playlist = [];
  String? _currentMood;
  bool _isLoading = false;
  final Map<String, String> _audioUrlCache = {};
  StreamSubscription? _playingSubscription;
  StreamSubscription? _processingSubscription;
  bool _isDisposed = false;

  Map<String, dynamic>? get currentTrack => _currentTrack;
  List<Map<String, dynamic>> get playlist => _playlist;
  String? get currentMood => _currentMood;
  bool get isLoading => _isLoading;
  bool get isPlaying => audioPlayer.playing;

  void _initializeListeners() {
    // Cancel existing subscriptions if they exist
    _playingSubscription?.cancel();
    _processingSubscription?.cancel();

    // Setup new subscriptions with proper error handling
    _playingSubscription = audioPlayer.playingStream.listen(
      (playing) {
        if (!_isDisposed) notifyListeners();
      },
      onError: (error) {
        print('Error in playing stream: $error');
      },
    );

    _processingSubscription = audioPlayer.processingStateStream.listen(
      (state) {
        if (!_isDisposed && state == ProcessingState.completed) {
          playNext();
        }
      },
      onError: (error) {
        print('Error in processing stream: $error');
      },
    );
  }

  // Initialize the service and restore state
  Future<void> initialize() async {
    if (_isDisposed) return;
    
    try {
      // Initialize statistics service first
      await _statisticsService.initialize();
      
      // Then restore state
      await restoreState();
      
      // Don't set up stream listeners here since they're handled in _initializeListeners
    } catch (e) {
      print('Error initializing AudioService: $e');
    }
  }

  // Save current state to SharedPreferences
  Future<void> saveState() async {
    if (_isDisposed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentTrack != null) {
        await prefs.setString('current_track', jsonEncode(_currentTrack));
      }
      if (_playlist.isNotEmpty) {
        await prefs.setString('playlist', jsonEncode(_playlist));
      }
      if (_currentMood != null) {
        await prefs.setString('current_mood', _currentMood!);
      }
      await prefs.setString('audioUrlCache', jsonEncode(_audioUrlCache));
    } catch (e) {
      print('Error saving audio state: $e');
    }
  }

  // Restore state from SharedPreferences
  Future<void> restoreState() async {
    if (_isDisposed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final savedTrack = prefs.getString('current_track');
      if (savedTrack != null) {
        _currentTrack = jsonDecode(savedTrack);
      }
      
      final savedPlaylist = prefs.getString('playlist');
      if (savedPlaylist != null) {
        _playlist = List<Map<String, dynamic>>.from(
          jsonDecode(savedPlaylist).map((x) => Map<String, dynamic>.from(x))
        );
      }
      
      _currentMood = prefs.getString('current_mood');

      final savedCache = prefs.getString('audioUrlCache');
      if (savedCache != null) {
        _audioUrlCache.clear();
        final Map<String, dynamic> decodedCache = jsonDecode(savedCache);
        decodedCache.forEach((key, value) {
          if (value is String) {
            _audioUrlCache[key] = value;
          }
        });
      }
      
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      print('Error restoring audio state: $e');
    }
  }

  // Clear saved state
  Future<void> clearState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_track');
      await prefs.remove('playlist');
      await prefs.remove('current_mood');
      await prefs.remove('audioUrlCache');
      
      await audioPlayer.stop();
      _currentTrack = null;
      _playlist = [];
      _currentMood = null;
      _isLoading = false;
      _audioUrlCache.clear();
      
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      print('Error clearing audio state: $e');
    }
  }

  Future<void> updateCurrentTrack(Map<String, dynamic> track) async {
    if (_isDisposed) return;
    _currentTrack = track;
    await saveState();
    notifyListeners();
  }

  Future<void> updatePlaylist(List<Map<String, dynamic>> tracks) async {
    if (_isDisposed) return;
    _playlist = tracks;
    await saveState();
    notifyListeners();
  }

  Future<void> updateMood(String mood) async {
    if (_isDisposed) return;
    _currentMood = mood;
    await saveState();
    // Start tracking new music session
    if (_currentMood != null && _playlist.isNotEmpty) {
      await _statisticsService.startMusicSession(
        mood: _currentMood!,
        genres: _playlist.map((track) => track['genre']?.toString() ?? 'unknown').toSet().toList(),
      );
    }
    notifyListeners();
  }

  void updateLoadingState(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    notifyListeners();
  }

  void updateAudioUrl(String videoId, String url) {
    _audioUrlCache[videoId] = url;
    saveState();
  }

  String? getAudioUrl(String videoId) {
    return _audioUrlCache[videoId];
  }

  Future<void> togglePlayback() async {
    if (_isDisposed || _currentTrack == null) return;
    
    try {
      _isLoading = false; // Immediately update UI state
      notifyListeners();
      
      if (audioPlayer.playing) {
        await audioPlayer.pause();
      } else {
        // Check if we need to set the audio source
        if (audioPlayer.audioSource == null) {
          String? audioUrl = getAudioUrl(_currentTrack!['id']);
          if (audioUrl != null) {
            _isLoading = true;
            notifyListeners();
            
            await audioPlayer.setAudioSource(
              AudioSource.uri(Uri.parse(audioUrl)),
              preload: true,
            ).timeout(const Duration(seconds: 5));
            
            _isLoading = false;
            notifyListeners();
          }
        }
        await audioPlayer.play();
      }
    } catch (e) {
      print('Error toggling playback: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> playNext() async {
    if (_isDisposed || _playlist.isEmpty || _currentTrack == null) return;
    
    try {
      final currentIndex = _playlist.indexOf(_currentTrack!);
      if (currentIndex < _playlist.length - 1) {
        final nextTrack = _playlist[currentIndex + 1];
        
        // Pre-fetch next track's URL if needed
        String? audioUrl = getAudioUrl(nextTrack['id']);
        if (audioUrl == null) return;

        await updateCurrentTrack(nextTrack);
        await startPlayback(audioUrl);
        
        // Prefetch the next-next track if available
        if (currentIndex < _playlist.length - 2) {
          final nextNextTrack = _playlist[currentIndex + 2];
          if (getAudioUrl(nextNextTrack['id']) == null) {
            // Prefetch in background
            _prefetchTrack(nextNextTrack['id']);
          }
        }
      }
    } catch (e) {
      print('Error in playNext: $e');
    }
  }

  Future<void> playPrevious() async {
    if (_isDisposed || _playlist.isEmpty || _currentTrack == null) return;
    
    try {
      final currentIndex = _playlist.indexOf(_currentTrack!);
      if (currentIndex > 0) {
        final previousTrack = _playlist[currentIndex - 1];
        
        String? audioUrl = getAudioUrl(previousTrack['id']);
        if (audioUrl == null) return;

        await updateCurrentTrack(previousTrack);
        await startPlayback(audioUrl);
      }
    } catch (e) {
      print('Error in playPrevious: $e');
    }
  }

  Future<bool> startPlayback(String audioUrl) async {
    if (_isDisposed) return false;
    
    try {
      _isLoading = true;
      notifyListeners();

      // Configure audio source with preloading
      final audioSource = AudioSource.uri(Uri.parse(audioUrl));
      
      // Set the audio source first
      await audioPlayer.setAudioSource(
        audioSource,
        preload: true,
      ).timeout(const Duration(seconds: 5));

      // Then start playback in a separate step
      final playbackStarted = audioPlayer.play().then((_) => true).catchError((error) {
        print('Error starting playback: $error');
        return false;
      });
      
      _isLoading = false;
      notifyListeners();
      
      return await playbackStarted;
    } catch (e) {
      print('Error in startPlayback: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _prefetchTrack(String videoId) async {
    try {
      if (!_audioUrlCache.containsKey(videoId)) {
        // Implement your URL fetching logic here
        // Example: final url = await youtubeService.getAudioUrl(videoId);
        // _audioUrlCache[videoId] = url;
      }
    } catch (e) {
      print('Error prefetching track: $e');
    }
  }

  bool hasPlaylist() {
    return _playlist.isNotEmpty;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _playingSubscription?.cancel();
    _processingSubscription?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }
} 