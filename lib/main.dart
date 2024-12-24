import 'package:flutter/material.dart';
import 'package:video_editor_app/video_editor/views/home_screen/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF181818),
      primary: const Color(0xFF181818),
      secondary: const Color(0xFF2F2F2F),
      surface: const Color(0xFF000000),
      onPrimary: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF2E85C0),
    );
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
