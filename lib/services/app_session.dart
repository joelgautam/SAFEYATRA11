import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  static String get apiBaseUrl {
    // For Android emulators, 10.0.2.2 points to the host machine's localhost
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    // For iOS, Web, and Desktop
    return 'http://127.0.0.1:8000/api';
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user['id']?.toString() ?? '');
    await prefs.setString('user_phone', user['phone']?.toString() ?? '');
    await prefs.setString(
        'user_full_name', user['full_name']?.toString() ?? '');
    await prefs.setString('user_email', user['email']?.toString() ?? '');
  }

  static Future<Map<String, String>> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString('user_id') ?? '',
      'phone': prefs.getString('user_phone') ?? '',
      'full_name': prefs.getString('user_full_name') ?? '',
      'email': prefs.getString('user_email') ?? '',
    };
  }

  static Future<void> saveActiveTripId(String tripId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_trip_id', tripId);
  }

  static Future<String> loadActiveTripId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('active_trip_id') ?? '';
  }

  static Future<void> clearActiveTripId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_trip_id');
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_phone');
    await prefs.remove('user_full_name');
    await prefs.remove('user_email');
    await prefs.remove('active_trip_id');
  }
}
