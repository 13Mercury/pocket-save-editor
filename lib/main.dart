import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const PocketSaveEditorApp());
}

class PocketSaveEditorApp extends StatelessWidget {
  const PocketSaveEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Save Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9E514B),
          surface: const Color(0xFFFFFEFC),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Colors.white,
          surfaceContainer: const Color(0xFFFFFEFD),
          surfaceContainerHigh: const Color(0xFFFFFEFD),
          surfaceContainerHighest: const Color(0xFFFFFEFD),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFEFC),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
