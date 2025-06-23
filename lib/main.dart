import 'package:flutter/material.dart';
import 'StartScreen.dart';
import 'audio_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AudioManager().playBackgroundMusic();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đuổi hình bắt chữ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}