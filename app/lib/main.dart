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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE1306C)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
