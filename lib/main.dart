import 'package:flutter/material.dart';
import 'screens/otp_login_screen.dart';
import 'screens/verified_screen.dart';
import 'screens/trip_setup_screen.dart';
import 'screens/passive_mode_screen.dart';
import 'screens/deviation_alert_screen.dart';

void main() {
  runApp(const SafeYatraApp());
}

class SafeYatraApp extends StatelessWidget {
  const SafeYatraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeYatra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B5FE6),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/otp',
      routes: {
        '/otp': (context) => const OtpLoginScreen(),
        '/verified': (context) => const VerifiedScreen(),
        '/trip': (context) => const TripSetupScreen(),
        '/passive': (context) => const PassiveModeScreen(),
        '/deviation': (context) => const DeviationAlertScreen(),
      },
    );
  }
}
