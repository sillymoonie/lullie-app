import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsService {
  static const String _musicSessionsKey = 'music_sessions';
  static const String _sleepDataKey = 'sleep_data';
  
  late SharedPreferences _prefs;
  
  // Singleton pattern
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Music Session Methods
  Future<void> startMusicSession({
    required String mood,
    required List<String> genres,
  }) async {
    final sessions = await getMusicSessions();
    sessions.add({
      'startTime': DateTime.now().toIso8601String(),
      'mood': mood,
      'genres': genres,
      'duration': 0, // Will be updated when session ends
    });
    await _saveMusicSessions(sessions);
  }

  Future<void> endMusicSession() async {
    final sessions = await getMusicSessions();
    if (sessions.isEmpty) return;

    final lastSession = sessions.last;
    final startTime = DateTime.parse(lastSession['startTime']);
    final duration = DateTime.now().difference(startTime).inMinutes;

    sessions.last = {
      ...lastSession,
      'duration': duration,
      'endTime': DateTime.now().toIso8601String(),
    };

    await _saveMusicSessions(sessions);
  }

  Future<List<Map<String, dynamic>>> getMusicSessions() async {
    final String? data = _prefs.getString(_musicSessionsKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  Future<void> _saveMusicSessions(List<Map<String, dynamic>> sessions) async {
    await _prefs.setString(_musicSessionsKey, jsonEncode(sessions));
  }

  // Sleep Data Methods
  Future<void> saveSleepData({
    required DateTime bedtime,
    required int durationMinutes,
    required int quality,
    String? notes,
  }) async {
    final sleepData = await getSleepData();
    sleepData.add({
      'date': DateTime.now().toIso8601String(),
      'bedtime': bedtime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'quality': quality,
      'notes': notes,
    });
    await _saveSleepData(sleepData);
  }

  Future<List<Map<String, dynamic>>> getSleepData() async {
    final String? data = _prefs.getString(_sleepDataKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  Future<void> _saveSleepData(List<Map<String, dynamic>> data) async {
    await _prefs.setString(_sleepDataKey, jsonEncode(data));
  }

  // Statistics Methods
  Future<Map<String, dynamic>> getWeeklyStats() async {
    final musicSessions = await getMusicSessions();
    final sleepData = await getSleepData();
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final recentSessions = musicSessions.where((session) {
      final date = DateTime.parse(session['startTime']);
      return date.isAfter(weekAgo);
    }).toList();

    final recentSleep = sleepData.where((data) {
      final date = DateTime.parse(data['date']);
      return date.isAfter(weekAgo);
    }).toList();

    return {
      'totalMusicSessions': recentSessions.length,
      'averageMusicDuration': recentSessions.isEmpty 
          ? 0 
          : recentSessions.map((s) => s['duration']).reduce((a, b) => a + b) / recentSessions.length,
      'averageSleepDuration': recentSleep.isEmpty 
          ? 0 
          : recentSleep.map((s) => s['durationMinutes']).reduce((a, b) => a + b) / recentSleep.length,
      'averageSleepQuality': recentSleep.isEmpty 
          ? 0 
          : recentSleep.map((s) => s['quality']).reduce((a, b) => a + b) / recentSleep.length,
    };
  }

  Future<Map<String, dynamic>> getMonthlyStats() async {
    final musicSessions = await getMusicSessions();
    final sleepData = await getSleepData();
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));

    final recentSessions = musicSessions.where((session) {
      final date = DateTime.parse(session['startTime']);
      return date.isAfter(monthAgo);
    }).toList();

    final recentSleep = sleepData.where((data) {
      final date = DateTime.parse(data['date']);
      return date.isAfter(monthAgo);
    }).toList();

    return {
      'totalMusicSessions': recentSessions.length,
      'averageMusicDuration': recentSessions.isEmpty 
          ? 0 
          : recentSessions.map((s) => s['duration']).reduce((a, b) => a + b) / recentSessions.length,
      'averageSleepDuration': recentSleep.isEmpty 
          ? 0 
          : recentSleep.map((s) => s['durationMinutes']).reduce((a, b) => a + b) / recentSleep.length,
      'averageSleepQuality': recentSleep.isEmpty 
          ? 0 
          : recentSleep.map((s) => s['quality']).reduce((a, b) => a + b) / recentSleep.length,
    };
  }
} 