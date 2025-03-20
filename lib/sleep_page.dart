import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _selectedDuration = const Duration(minutes: 30);
  bool _isTimerRunning = false;
  DateTime? _bedtime;
  int _sleepQuality = 0;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startSleepTimer() {
    setState(() {
      _isTimerRunning = true;
    });
    
    // Play some white noise or calming sounds
    // TODO: Add your audio file path here
    // _audioPlayer.setAsset('assets/audio/white_noise.mp3');
    // _audioPlayer.play();

    Future.delayed(_selectedDuration, () {
      if (_isTimerRunning) {
        _audioPlayer.stop();
        setState(() {
          _isTimerRunning = false;
        });
        _showWakeUpNotification();
      }
    });
  }

  void _stopSleepTimer() {
    setState(() {
      _isTimerRunning = false;
    });
    _audioPlayer.stop();
  }

  void _showWakeUpNotification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        title: Text(
          'Sleep Timer Ended',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        content: Text(
          'How was your sleep quality?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => 
              IconButton(
                icon: Icon(
                  index < _sleepQuality ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() {
                    _sleepQuality = index + 1;
                  });
                },
              ),
            ),
          ),
          TextButton(
            child: Text(
              'Save',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            onPressed: () {
              // TODO: Save sleep quality data
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _startBreathingExercise() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BreathingExerciseDialog(),
    );
  }

  void _setBedtimeReminder() async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.deepPurple.shade900,
              hourMinuteTextColor: Colors.white,
              dayPeriodTextColor: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.white),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        final now = DateTime.now();
        _bedtime = DateTime(
          now.year,
          now.month,
          now.day,
          selectedTime.hour,
          selectedTime.minute,
        );
      });
      // TODO: Schedule actual notification
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sleep',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/lulify-bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sleep Better',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track and improve your sleep quality',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Sleep Timer Section
                _buildCard(
                  title: 'Sleep Timer',
                  child: Column(
                    children: [
                      DropdownButton<Duration>(
                        value: _selectedDuration,
                        dropdownColor: Colors.deepPurple.shade900,
                        style: GoogleFonts.inter(color: Colors.white),
                        items: [
                          const Duration(minutes: 15),
                          const Duration(minutes: 30),
                          const Duration(minutes: 45),
                          const Duration(minutes: 60),
                        ].map((duration) {
                          return DropdownMenuItem<Duration>(
                            value: duration,
                            child: Text('${duration.inMinutes} minutes'),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() => _selectedDuration = newValue);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTimerRunning ? Colors.red : Colors.deepPurple,
                          minimumSize: const Size(double.infinity, 45),
                        ),
                        onPressed: _isTimerRunning ? _stopSleepTimer : _startSleepTimer,
                        child: Text(
                          _isTimerRunning ? 'Stop Timer' : 'Start Timer',
                          style: GoogleFonts.inter(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.bedtime,
                        label: 'Set Bedtime',
                        onTap: _setBedtimeReminder,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.air,
                        label: 'Breathing',
                        onTap: _startBreathingExercise,
                      ),
                    ),
                  ],
                ),
                
                if (_bedtime != null) ...[
                  const SizedBox(height: 20),
                  _buildCard(
                    title: 'Bedtime Reminder',
                    child: Text(
                      'Reminder set for ${TimeOfDay.fromDateTime(_bedtime!).format(context)}',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class BreathingExerciseDialog extends StatefulWidget {
  @override
  State<BreathingExerciseDialog> createState() => _BreathingExerciseDialogState();
}

class _BreathingExerciseDialogState extends State<BreathingExerciseDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStep = 0;
  final List<Map<String, dynamic>> _steps = [
    {'text': 'Inhale...', 'duration': 4},
    {'text': 'Hold...', 'duration': 7},
    {'text': 'Exhale...', 'duration': 8},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _steps[_currentStep]['duration']),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_currentStep < _steps.length - 1) {
          setState(() {
            _currentStep++;
            _controller.duration = Duration(seconds: _steps[_currentStep]['duration']);
          });
          _controller.forward(from: 0);
        } else {
          setState(() {
            _currentStep = 0;
            _controller.duration = Duration(seconds: _steps[_currentStep]['duration']);
          });
          _controller.forward(from: 0);
        }
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.deepPurple.shade900,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _steps[_currentStep]['text'],
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CircularProgressIndicator(
                value: _controller.value,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 8,
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text(
            'End Session',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
