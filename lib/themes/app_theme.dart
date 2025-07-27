import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dreamTheme = ThemeData(
    scaffoldBackgroundColor: const Color(0xFF0B0C2A),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
    fontFamily: 'DreamFont',
  );
}
