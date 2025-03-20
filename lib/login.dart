import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _navigateToHome(BuildContext context) async {
    try {
      print('Navigating to home screen...');
      // Store guest status in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', true);
      print('Guest status stored successfully');
      
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      print('Error during navigation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('Screen tapped');
        _navigateToHome(context);
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Background Image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/login/login-bg.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      "assets/images/login/lullie-logo.png",
                      width: 120,
                    ),
                    const SizedBox(height: 30),

                    // Welcome Text
                    const Text(
                      "Welcome to Lullie",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Your personal sleep companion for better rest",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Tap anywhere to continue",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 