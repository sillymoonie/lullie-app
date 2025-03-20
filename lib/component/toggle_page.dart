import 'package:lullie_app/on_boarding.dart';
import 'package:flutter/material.dart';
import 'package:lullie_app/prompt_screen.dart';

class TogglePage extends StatefulWidget {
  const TogglePage({super.key});

  @override
  State<TogglePage> createState() => _TogglePageState();
}

class _TogglePageState extends State<TogglePage> {
  bool _showOnBoarding = true;

  void _toggleScreen() {
    setState(() {
      _showOnBoarding = !_showOnBoarding;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnBoarding) {
      return OnBoarding(
        showPromptScreen: _toggleScreen,
      );
    } else {
      return PromptScreen(
        showHomeScreen: _toggleScreen,
      );
    }
  }
}
