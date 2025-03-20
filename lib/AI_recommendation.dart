import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:lullie_app/prompt_screen.dart';
import 'package:flutter/services.dart';

class AIRecommendation extends StatefulWidget {
  final VoidCallback showHomeScreen;

  const AIRecommendation({
    Key? key,
    required this.showHomeScreen,
  }) : super(key: key);

  @override
  _AIRecommendationState createState() => _AIRecommendationState();
}

class _AIRecommendationState extends State<AIRecommendation> with SingleTickerProviderStateMixin {
  final Random random = Random();
  String? _selectedMood;
  String? _selectedMoodImage;
  final Set<String> _selectedGenres = {};
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> genres = ['Lofi', 'Jazz', 'Classical', 'Nature', 'Ambient', 'White Noise'];
  final List<Map<String, String>> moodData = [
    {'mood': 'Happy', 'image': 'assets/images/happy.png'},
    {'mood': 'Heartbroken', 'image': 'assets/images/heartbroken.png'},
    {'mood': 'Grateful', 'image': 'assets/images/grateful.png'},
    {'mood': 'Relaxed', 'image': 'assets/images/relaxed.png'},
    {'mood': 'Anxious', 'image': 'assets/images/anxious.png'},
    {'mood': 'Romance', 'image': 'assets/images/romance.png'},
    {'mood': 'Energetic', 'image': 'assets/images/energetic.png'},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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

  void _navigateToPromptScreen() {
    if (_selectedMood == null || _selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both mood and genres')),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => PromptScreen(
          showHomeScreen: widget.showHomeScreen,
          initialMood: _selectedMood!,
          initialMoodImage: _selectedMoodImage!,
          initialGenres: _selectedGenres.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.showHomeScreen();
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SmoothCursorWidget(
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            widget.showHomeScreen();
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      Text(
                        "Create Playlist",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                      decelerationRate: ScrollDecelerationRate.fast,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mood Question
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              "How are you feeling today?",
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Mood Selection
                          Container(
                            height: 300,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final List<Widget> circles = [];
                                final List<Rect> positions = [];

                                for (int i = 0; i < moodData.length; i++) {
                                  final double size = random.nextDouble() * 80 + 60;
                                  double left, top;
                                  Rect newPosition;

                                  bool doesOverlap;
                                  int attempts = 0;
                                  const int maxAttempts = 100;

                                  do {
                                    left = random.nextDouble() * (constraints.maxWidth - size);
                                    top = random.nextDouble() * (constraints.maxHeight - size);
                                    newPosition = Rect.fromLTWH(left, top, size, size);

                                    doesOverlap = positions.any((position) => position.overlaps(newPosition));
                                    attempts++;
                                  } while (doesOverlap && attempts < maxAttempts);

                                  if (attempts == maxAttempts) continue;

                                  positions.add(newPosition);

                                  circles.add(
                                    Positioned(
                                      left: left,
                                      top: top,
                                      child: SmoothCursorWidget(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (_selectedMood == moodData[i]['mood']) {
                                                _selectedMood = null;
                                                _selectedMoodImage = null;
                                              } else {
                                                _selectedMood = moodData[i]['mood'];
                                                _selectedMoodImage = moodData[i]['image'];
                                              }
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                width: _selectedMood == moodData[i]['mood'] ? 3.0 : 2.0,
                                                color: _selectedMood == moodData[i]['mood']
                                                    ? const Color(0xFFB37FEB)
                                                    : Colors.white.withOpacity(0.3),
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: _selectedMood == moodData[i]['mood']
                                                  ? [
                                                      BoxShadow(
                                                        color: const Color(0xFFB37FEB).withOpacity(0.5),
                                                        blurRadius: 15,
                                                        spreadRadius: 5,
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Container(
                                              width: size,
                                              height: size,
                                              decoration: BoxDecoration(
                                                color: _selectedMood == moodData[i]['mood']
                                                    ? const Color(0xFFB37FEB).withOpacity(0.2)
                                                    : Colors.white.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Image.asset(
                                                moodData[i]['image']!,
                                                width: size * 0.8,
                                                height: size * 0.8,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return Stack(children: circles);
                              },
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Genre Selection
                          Text(
                            "What genre would you like to listen to?",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: genres.map((genre) {
                              final isSelected = _selectedGenres.contains(genre);
                              return SmoothCursorWidget(
                                child: GestureDetector(
                                  onTap: () => _onGenreTap(genre),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFB37FEB)
                                          : Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFB37FEB).withOpacity(0.3),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      genre,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 40),

                          // Generate Button
                          SmoothCursorWidget(
                            child: GestureDetector(
                              onTap: _navigateToPromptScreen,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFB37FEB),
                                      Color(0xFF9B51E0),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFB37FEB).withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Generate Playlist',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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