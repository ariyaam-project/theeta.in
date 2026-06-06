import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'pages/main_shell.dart';
import 'state/app_state.dart';
import 'theme.dart';

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
          seedColor: accent,
          primary: accent,
          secondary: gold,
          surface: paper,
        ),
        scaffoldBackgroundColor: bg,
        fontFamily: 'Helvetica',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: ink,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: ink,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        cardTheme: CardThemeData(
          color: paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: const BorderSide(color: ink, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          ),
        ),
      ),
      home: const AppRoot(),
    );
  }
}

/// Auth gate: boots [AppState], then shows the login page or the main shell.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.bootstrap();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        if (!_state.bootstrapped) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _state.loggedIn
            ? MainShell(state: _state)
            : LoginPage(state: _state);
      },
    );
  }
}
