import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'StartScreen.dart';
import 'audio_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  AudioManager().playBackgroundMusic();
  runApp(
    const ProviderScope(
    child: MyApp(),
    ),
  );
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