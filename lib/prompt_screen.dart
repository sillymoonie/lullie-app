import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lullie_app/AI_recommendation.dart';
import 'package:lullie_app/services/youtube_service.dart';
import 'dart:convert';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:lullie_app/services/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

class PromptScreen extends StatefulWidget {
  final VoidCallback showHomeScreen;
  final String initialMood;
  final String initialMoodImage;
  final List<String> initialGenres;

  const PromptScreen({
    super.key, 
    required this.showHomeScreen,
    required this.initialMood,
    required this.initialMoodImage,
    required this.initialGenres,
  });

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen> {
  final List<String> genres = ['Lofi', 'Jazz', 'Classical', 'Nature', 'Ambient', 'White Noise'];
  Set<String> _selectedGenres = {};
  String? _selectedMood;
  String? _selectedMoodImage;
  bool _isLoading = false;

  final YouTubeService _youtubeService = YouTubeService();
  final AudioService _audioService = AudioService();
  List<Map<String, dynamic>> _youtubeTracks = [];
  Map<String, dynamic>? _currentTrack;
  bool _isPlaying = false;
  final TextEditingController _promptController = TextEditingController();
  final List<String> _thumbnails = [
    'assets/images/music-thumnails/01.jpeg',
    'assets/images/music-thumnails/02.jpeg',
    'assets/images/music-thumnails/03.jpeg',
    'assets/images/music-thumnails/04.jpeg',
    'assets/images/music-thumnails/05.jpeg',
    'assets/images/music-thumnails/06.jpeg',
    'assets/images/music-thumnails/07.jpeg',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMood;
    _selectedMoodImage = widget.initialMoodImage;
    _selectedGenres = Set<String>.from(widget.initialGenres);
    _initializeScreen();
    // Start generating playlist immediately if we have mood and genres
    if (_selectedMood != null && _selectedGenres.isNotEmpty) {
      _submitSelections();
    }
  }

  Future<void> _initializeScreen() async {
    await _initializeAudio();
    
    // If we have an existing playlist, restore it
    if (_audioService.hasPlaylist()) {
      setState(() {
        _youtubeTracks = _audioService.playlist;
        _currentTrack = _audioService.currentTrack;
        _selectedMood = _audioService.currentMood;
        _isPlaying = _audioService.isPlaying;
      });

      // If there's a current track, prepare it for playback
      if (_currentTrack != null) {
        final audioUrl = _audioService.getAudioUrl(_currentTrack!['id']);
        if (audioUrl != null) {
          await _startPlayback(audioUrl);
        } else {
          // If URL not in cache, fetch it
          try {
            final newUrl = await _youtubeService.getAudioUrl(_currentTrack!['id']);
            _audioService.updateAudioUrl(_currentTrack!['id'], newUrl);
            await _startPlayback(newUrl);
          } catch (e) {
            print('Error fetching audio URL during restoration: $e');
          }
        }
      }
    }
  }

  void _onGenreTap(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  @override
  void dispose() {
    // Cleanup all streams and audio resources
    _audioService.audioPlayer.playingStream.drain();
    _audioService.audioPlayer.positionStream.drain();
    _audioService.audioPlayer.bufferedPositionStream.drain();
    _audioService.audioPlayer.sequenceStateStream.drain();
    _audioService.audioPlayer.stop();
    _audioService.audioPlayer.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _initializeAudio() async {
    try {
      // Configure audio player
      await _audioService.initialize();
      
      // Setup stream listeners with error handling
      _audioService.audioPlayer.playingStream.listen(
        (playing) {
          if (mounted) {
            setState(() => _isPlaying = playing);
          }
        },
        onError: (dynamic e) {
          print('Error in playingStream: $e');
        },
      );

      _audioService.audioPlayer.processingStateStream.listen(
        (state) {
          if (state == ProcessingState.completed) {
            _playNextTrack();
          }
        },
        onError: (dynamic e) {
          print('Error in processingStateStream: $e');
        },
      );

      // Add error handling for audio player
      _audioService.audioPlayer.playerStateStream.listen(
        (state) {
          if (mounted && state.processingState == ProcessingState.completed) {
            _playNextTrack();
          }
        },
        onError: (dynamic e) {
          print('Error in playerStateStream: $e');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isPlaying = false;
            });
            _playNextTrack();
          }
        },
      );
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  Future<void> _submitSelections() async {
    if (_selectedMood?.isEmpty ?? true || _selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both mood and genres')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _youtubeTracks = [];
      _currentTrack = null;
      _isPlaying = false;
    });

    try {
      final promptText = '''
Suggest 8 popular ${_selectedGenres.join('/')} songs for ${_selectedMood!.toLowerCase()} mood.
Format: "Artist - Song Title". Only real, calming songs. No duplicates. 
Return exactly 8 songs.
''';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['token']}',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [{"role": "user", "content": promptText}],
          "max_tokens": 200,
          "temperature": 0.5
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) throw Exception('Failed to get recommendations');

      final data = json.decode(response.body);
      final choices = data['choices'] as List;
      if (choices.isEmpty) throw Exception('No recommendations received');

      final playlistString = choices[0]['message']['content'] as String;
      final recommendations = playlistString
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.replaceAll(RegExp(r'^\d+\.\s*'), '').trim())
          .where((line) => line.contains('-'))
          .take(8)
          .toList();

      if (recommendations.isEmpty) throw Exception('No valid song formats found');

      final futures = recommendations.map((song) => _youtubeService.searchTracks(song));
      final searchResults = await Future.wait(futures);
      
      final tracks = searchResults
          .where((results) => results.isNotEmpty)
          .map((results) => results.first)
          .toList();

      if (tracks.isEmpty) throw Exception('No tracks found');

      // Create a copy of thumbnails list and shuffle it
      final availableThumbnails = List<String>.from(_thumbnails);
      availableThumbnails.shuffle();
      
      // Ensure we have enough thumbnails
      if (availableThumbnails.length < tracks.length) {
        throw Exception('Not enough unique thumbnails for tracks');
      }

      // Assign thumbnails sequentially from shuffled list
      final updatedTracks = List<Map<String, dynamic>>.from(tracks);
      for (int i = 0; i < updatedTracks.length; i++) {
        updatedTracks[i] = {
          ...updatedTracks[i],
          'thumbnail': availableThumbnails[i],
        };
      }

      setState(() => _youtubeTracks = updatedTracks);

      // Update AudioService with new playlist
      _audioService.updatePlaylist(updatedTracks);
      _audioService.updateMood(_selectedMood ?? '');

      await _prefetchAudioUrls(updatedTracks);

    } catch (e) {
      print('Error in _submitSelections: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating playlist. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _prefetchAudioUrls(List<Map<String, dynamic>> tracks) async {
    if (!mounted) return;
    
    try {
      // Create a queue for prefetching
      final prefetchQueue = tracks.take(3).toList(); // Prefetch first 3 tracks
      
      // Prefetch in parallel with reduced timeout
      await Future.wait(
        prefetchQueue.map((track) async {
          final videoId = track['id'] as String;
          try {
            if (_audioService.getAudioUrl(videoId) == null) {
              final url = await _youtubeService.getAudioUrl(videoId)
                  .timeout(const Duration(seconds: 5));
              _audioService.updateAudioUrl(videoId, url);
              print('Successfully prefetched: ${track['title']}');
            }
          } catch (e) {
            print('Error prefetching ${track['title']}: $e');
          }
        }),
        eagerError: false,
      );

      // Background prefetch remaining tracks
      Future(() async {
        for (final track in tracks.skip(3)) {
          if (!mounted) return; // Stop if widget is disposed
          
          try {
            final videoId = track['id'] as String;
            if (_audioService.getAudioUrl(videoId) == null) {
              final url = await _youtubeService.getAudioUrl(videoId)
                  .timeout(const Duration(seconds: 5));
              _audioService.updateAudioUrl(videoId, url);
              print('Background prefetch success: ${track['title']}');
            }
          } catch (e) {
            print('Background prefetch error: $e');
          }
          
          // Small delay between prefetches to avoid overwhelming
          await Future.delayed(const Duration(milliseconds: 500));
        }
      });

    } catch (e) {
      print('Error in prefetchAudioUrls: $e');
    }
  }

  Future<void> _togglePlayback(Map<String, dynamic> track) async {
    if (_isLoading) return;

    try {
      // If it's the current track, just toggle play/pause
      if (_currentTrack?['id'] == track['id']) {
        setState(() => _isPlaying = !_isPlaying);
        if (_isPlaying) {
          await _audioService.audioPlayer.play();
        } else {
          await _audioService.audioPlayer.pause();
        }
        return;
      }

      setState(() {
        _isLoading = true;
        _currentTrack = track;
      });

      // Update service state immediately
      _audioService.updateCurrentTrack(track);
      _audioService.updatePlaylist(_youtubeTracks);

      // Get audio URL from cache or fetch new one
      String? audioUrl = _audioService.getAudioUrl(track['id']);
      if (audioUrl == null) {
        try {
          audioUrl = await _youtubeService.getAudioUrl(track['id'])
              .timeout(const Duration(seconds: 3));
          _audioService.updateAudioUrl(track['id'], audioUrl);
        } catch (e) {
          print('Error getting audio URL: $e');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isPlaying = false;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to play track. Please try again.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }

      // Configure audio source with error handling
      final audioSource = AudioSource.uri(Uri.parse(audioUrl));
      
      await _audioService.audioPlayer.setAudioSource(
        audioSource,
        preload: true,
      ).timeout(const Duration(seconds: 3));

      // Start playback immediately
      await _audioService.audioPlayer.play();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlaying = true;
        });
      }
      
      // Prepare next track in background
      _prepareNextTrack();
      
    } catch (e) {
      print('Error in togglePlayback: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlaying = false;
        });
      }
    }
  }

  Future<bool> _startPlayback(String audioUrl) async {
    int retryCount = 0;
    const maxRetries = 3;

    try {
      while (retryCount < maxRetries && mounted) {
        try {
          // Configure audio source with error handling
          final audioSource = AudioSource.uri(Uri.parse(audioUrl));
          
          await _audioService.audioPlayer.setAudioSource(
            audioSource,
            preload: true,
          ).timeout(const Duration(seconds: 5));

          // Start playback immediately after source is set
          await _audioService.audioPlayer.play();
          
          if (mounted) {
            setState(() {
              _isPlaying = true;
              _isLoading = false;
            });
          }
          
          // Setup progress tracking in background
          _setupProgressTracking();
          
          return true;
          
        } catch (e) {
          print('Playback attempt ${retryCount + 1} failed: $e');
          retryCount++;
          
          if (retryCount < maxRetries) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      // If all retries failed, try to get a fresh URL
      if (mounted && _currentTrack != null) {
        try {
          final newUrl = await _youtubeService.getAudioUrl(_currentTrack!['id']);
          _audioService.updateAudioUrl(_currentTrack!['id'], newUrl);
          return await _startPlayback(newUrl);
        } catch (e) {
          print('Error getting fresh URL: $e');
        }
      }

      return false;
      
    } catch (e) {
      print('Error in _startPlayback: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlaying = false;
        });
      }
      return false;
    }
  }

  void _setupProgressTracking() {
    _audioService.audioPlayer.positionStream
        .listen(
          (position) {
            if (!mounted) return;
            
            final duration = _audioService.audioPlayer.duration;
            if (duration != null) {
              final remainingTime = duration - position;
              if (remainingTime.inSeconds < 10) {
                _prepareNextTrack();
              }
            }
          },
          onError: (dynamic error) {
            print('Error tracking position: $error');
          },
        );
  }

  Future<void> _prepareNextTrack() async {
    if (_currentTrack == null || !mounted) return;
    
    try {
      final currentIndex = _youtubeTracks.indexOf(_currentTrack!);
      if (currentIndex < _youtubeTracks.length - 1) {
        final nextTrack = _youtubeTracks[currentIndex + 1];
        final videoId = nextTrack['id'] as String;
        
        // Only fetch if not already in cache
        if (_audioService.getAudioUrl(videoId) == null) {
          final url = await _youtubeService.getAudioUrl(videoId)
              .timeout(const Duration(seconds: 5));
          _audioService.updateAudioUrl(videoId, url);
        }
      }
    } catch (e) {
      print('Error in _prepareNextTrack: $e');
    }
  }

  void _playNextTrack() {
    if (_currentTrack == null || !mounted) return;
    
    final currentIndex = _youtubeTracks.indexOf(_currentTrack!);
    if (currentIndex < _youtubeTracks.length - 1) {
      _togglePlayback(_youtubeTracks[currentIndex + 1]);
    } else {
      // End of playlist reached
      setState(() {
        _isPlaying = false;
        _isLoading = false;
      });
    }
  }

  String getRandomThumbnail() {
    final random = Random();
    return _thumbnails[random.nextInt(_thumbnails.length)];
  }

  void _showNewPlaylist() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AIRecommendation(
          showHomeScreen: widget.showHomeScreen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Don't stop playback when going back
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/lulify-bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _youtubeTracks.isEmpty
                  ? _isLoading 
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No playlist generated yet',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SmoothCursorWidget(
                                child: ElevatedButton(
                                  onPressed: _showNewPlaylist,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFB37FEB),
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Create New Playlist',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                  : Column(
                      children: [
                        if (_currentTrack != null) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _currentTrack = null;
                                          _audioService.audioPlayer.stop();
                                        });
                                      },
                                    ),
                                    Text(
                                      'Now Playing',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: SvgPicture.asset(
                                        'assets/images/nav-bar/home-icon.svg',
                                        width: 24,
                                        height: 24,
                                        colorFilter: const ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      onPressed: () {
                                        // Don't stop playback when going home
                                        Navigator.of(context).pop();
                                        widget.showHomeScreen();
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.6,
                                      height: MediaQuery.of(context).size.width * 0.6,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFB37FEB).withOpacity(0.3),
                                            blurRadius: 15,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: Image.asset(
                                          _currentTrack!['thumbnail'],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    if (_isLoading)
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.6,
                                        height: MediaQuery.of(context).size.width * 0.6,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _currentTrack?['title'] ?? 'Unknown Track',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _currentTrack?['artist'] ?? 'Unknown Artist',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.skip_previous,
                                        color: Colors.white,
                                        size: 35,
                                      ),
                                      onPressed: _isLoading ? null : () {
                                        final currentIndex = _youtubeTracks.indexOf(_currentTrack!);
                                        if (currentIndex > 0) {
                                          _togglePlayback(_youtubeTracks[currentIndex - 1]);
                                        }
                                      },
                                    ),
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _isLoading 
                                              ? const Color(0xFFB37FEB).withOpacity(0.5)
                                              : const Color(0xFFB37FEB),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFB37FEB).withOpacity(0.3),
                                              blurRadius: 15,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            _isLoading ? Icons.hourglass_empty :
                                            _isPlaying ? Icons.pause : Icons.play_arrow,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                          onPressed: _isLoading ? null : () => _togglePlayback(_currentTrack!),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.skip_next,
                                        color: Colors.white,
                                        size: 35,
                                      ),
                                      onPressed: _isLoading ? null : _playNextTrack,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Expanded(
                          child: ScrollConfiguration(
                            behavior: CustomScrollBehavior(),
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              itemCount: _youtubeTracks.length,
                              itemBuilder: (context, index) {
                                final track = _youtubeTracks[index];
                                final isCurrentTrack = _currentTrack?['id'] == track['id'];
                                
                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: _isLoading && isCurrentTrack ? null : () => _togglePlayback(track),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isCurrentTrack ? const Color(0xFFB37FEB) : Colors.transparent,
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(8),
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.asset(
                                            track['thumbnail'],
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        title: Text(
                                          track['title'] ?? 'Unknown Track',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          track['artist'] ?? 'Unknown Artist',
                                          style: GoogleFonts.inter(
                                            color: Colors.white70,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: IconButton(
                                            icon: Icon(
                                              isCurrentTrack && _isPlaying
                                                  ? Icons.pause_circle_filled
                                                  : Icons.play_circle_filled,
                                              color: const Color(0xFFB37FEB),
                                              size: 40,
                                            ),
                                            onPressed: _isLoading && isCurrentTrack ? null : () => _togglePlayback(track),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
      decelerationRate: ScrollDecelerationRate.fast,
    );
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return Theme(
      data: ThemeData(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: MaterialStateProperty.all(
            const Color(0xFFB37FEB).withOpacity(0.5),
          ),
          thickness: MaterialStateProperty.all(6.0),
          radius: const Radius.circular(3.0),
          thumbVisibility: MaterialStateProperty.all(true),
        ),
      ),
      child: Scrollbar(
        controller: details.controller,
        child: child,
      ),
    );
  }

  @override
  MouseCursor getSystemMouseCursor(BuildContext context, PointerDeviceKind deviceKind) {
    return SystemMouseCursors.click;
  }
}

class SmoothCursorWidget extends StatelessWidget {
  final Widget child;
  final SystemMouseCursor cursor;

  const SmoothCursorWidget({
    Key? key,
    required this.child,
    this.cursor = SystemMouseCursors.click,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: child,
    );
  }
}
