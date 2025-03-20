import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lullie_app/prompt_screen.dart';
import 'package:lullie_app/sleep_page.dart';
import 'package:lullie_app/statistic_page.dart';
import 'package:lullie_app/profile_page.dart';
import 'package:lullie_app/services/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:lullie_app/ai_recommendation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 3; // Default to 'Home' screen
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _initializeAudioService();
  }

  Future<void> _initializeAudioService() async {
    await _audioService.initialize();
    _audioService.audioPlayer.playingStream.listen((playing) {
      if (mounted) {
        setState(() {}); // Trigger rebuild when playing state changes
      }
    });
  }

  void _navigateToMusic() {
    // Always navigate to AI recommendation screen first
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AIRecommendation(
          showHomeScreen: () {
            Navigator.of(context).pop();
            setState(() => _selectedIndex = 3);
          },
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      
      // Show PromptScreen when Music tab (index 0) is selected
      if (index == 0) {
        _navigateToMusic();
      }
      // Show SleepPage when Sleep tab (index 1) is selected
      else if (index == 1) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SleepPage(),
          ),
        );
      }
      // Show StatisticPage when Statistic tab (index 2) is selected
      else if (index == 2) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const StatisticPage(),
          ),
        );
      }
      // Show ProfilePage when Profile tab (index 3) is selected
      else if (index == 3) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ProfilePage(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _audioService,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/lulify-bg.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Good evening, Harley!",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Let's prepare for sleep",
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tonight's Playlist Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: _navigateToMusic,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(
                                  "assets/images/nav-bar/music-icon.svg",
                                  width: 20,
                                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _audioService.currentMood != null 
                                    ? "Currently Playing - ${_audioService.currentMood} mood" 
                                    : "Tap to create a playlist",
                                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _audioService.currentTrack?['title'] ?? "No track playing",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _audioService.currentTrack?['artist'] ?? "Select your mood and create a playlist",
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_audioService.currentTrack != null) ...[
                                  IconButton(
                                    icon: const Icon(
                                      Icons.skip_previous,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    onPressed: _audioService.isLoading ? null : _audioService.playPrevious,
                                  ),
                                ],
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: FloatingActionButton(
                                    backgroundColor: Colors.white,
                                    onPressed: _audioService.isLoading ? null : () {
                                      if (_audioService.currentTrack == null) {
                                        _navigateToMusic();
                                      } else {
                                        _audioService.togglePlayback();
                                      }
                                    },
                                    child: _audioService.isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB37FEB)),
                                          ),
                                        )
                                      : Icon(
                                          _audioService.currentTrack == null ? Icons.add 
                                            : (_audioService.isPlaying ? Icons.pause : Icons.play_arrow),
                                          color: const Color(0xFFB37FEB),
                                        ),
                                  ),
                                ),
                                if (_audioService.currentTrack != null) ...[
                                  IconButton(
                                    icon: const Icon(
                                      Icons.skip_next,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    onPressed: _audioService.isLoading ? null : _audioService.playNext,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Sleep Summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sleep Summary",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _summaryItem("7h 30m", "Duration", "assets/images/nav-bar/sleep-icon.svg"),
                              _summaryItem("85%", "Quality", "assets/images/nav-bar/statistics-icon.svg"),
                              _summaryItem("45m", "Music", "assets/images/nav-bar/music-icon.svg"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom Navigation Bar
                  Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: const Color(0xFF1A1A2E),
                    ),
                    child: BottomNavigationBar(
                      backgroundColor: const Color(0xFF1A1A2E),
                      selectedItemColor: Colors.white,
                      unselectedItemColor: Colors.white70,
                      currentIndex: _selectedIndex,
                      onTap: _onItemTapped,
                      type: BottomNavigationBarType.fixed,
                      selectedLabelStyle: GoogleFonts.inter(fontSize: 12),
                      unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
                      items: [
                        _navBarItem("Music", "assets/images/nav-bar/music-icon.svg"),
                        _navBarItem("Sleep", "assets/images/nav-bar/sleep-icon.svg"),
                        _navBarItem("Statistic", "assets/images/nav-bar/statistic-icon.svg"),
                        _navBarItem("Profile", "assets/images/nav-bar/profile-icon.svg"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryItem(String value, String label, String iconPath) {
    return Column(
      children: [
        SvgPicture.asset(
          iconPath, 
          width: 30, 
          height: 30,
          colorFilter: const ColorFilter.mode(Colors.deepPurple, BlendMode.srcIn),
        ),
        const SizedBox(height: 8),
        Text(
          value, 
          style: GoogleFonts.inter(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label, 
          style: GoogleFonts.inter(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  BottomNavigationBarItem _navBarItem(String label, String iconPath) {
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        iconPath, 
        width: 24, 
        height: 24, 
        colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
        fit: BoxFit.contain,
      ),
      activeIcon: SvgPicture.asset(
        iconPath, 
        width: 24, 
        height: 24, 
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        fit: BoxFit.contain,
      ),
      label: label,
    );
  }
} 