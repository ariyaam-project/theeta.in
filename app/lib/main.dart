import 'package:flutter/material.dart';

import 'pages/home_page.dart';

void main() {
  runApp(const ThetaApp());
}

class ThetaApp extends StatelessWidget {
  const ThetaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE1306C),
          primary: const Color(0xFFE1306C),
          secondary: const Color(0xFFF7AB3F),
          surface: const Color(0xFFFFF8EC),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF4E0),
        fontFamily: 'Helvetica',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF4E0),
          foregroundColor: Color(0xFF2F231A),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF2F231A),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFF8EC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: const BorderSide(color: Color(0xFF2F231A), width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE1306C),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
