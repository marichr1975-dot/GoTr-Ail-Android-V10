import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GoTrApp());
}

class GoTrApp extends StatelessWidget {
  const GoTrApp({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF0C5FA8);
    const green = Color(0xFF2E8B57);
    const ink = Color(0xFF10231B);
    return MaterialApp(
      title: 'GoTr-AI 9.6 MWM ONLY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
        colorScheme: ColorScheme.fromSeed(seedColor: blue).copyWith(
          primary: blue,
          secondary: green,
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.w900, color: ink),
          headlineMedium: TextStyle(fontWeight: FontWeight.w900, color: ink),
          titleLarge: TextStyle(fontWeight: FontWeight.w900, color: ink),
          bodyLarge: TextStyle(color: ink),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
