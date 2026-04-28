import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/history_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/settings_screen.dart';

class BlackjackApp extends StatelessWidget {
  const BlackjackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlackJack Royal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD700),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D2B0D),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/':           (_) => const SplashScreen(),
        '/home':       (_) => const HomeScreen(),
        '/game':       (_) => const GameScreen(),
        '/history':    (_) => const HistoryScreen(),
        '/leaderboard': (_) => const LeaderboardScreen(),
        '/settings':   (_) => const SettingsScreen(),
      },
    );
  }
}
