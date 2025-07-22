import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart'; // <-- THÊM DÒNG NÀY
import 'package:firebase_analytics/firebase_analytics.dart'; // <-- THÊM DÒNG NÀY
import 'firebase_options.dart'; // <-- THÊM DÒNG NÀY (quan trọng)
import 'StartScreen.dart';
import 'audio_manager.dart';

void main() async {
  // Đảm bảo Flutter binding đã được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // KHỞI TẠO FIREBASE TRƯỚC BẤT KỲ CÁC PLUGIN FIREBASE NÀO KHÁC
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khởi tạo Mobile Ads (nếu có sử dụng AdMob)
  await MobileAds.instance.initialize();

  // Phát nhạc nền (từ code của bạn)
  AudioManager().playBackgroundMusic();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Tạo một đối tượng FirebaseAnalytics để sử dụng
  // Đây là cách tốt để truy cập Firebase Analytics trên toàn ứng dụng
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
  FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đuổi hình bắt chữ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StartScreen(),
      debugShowCheckedModeBanner: false,
      // Đặt navigatorObservers để tự động ghi lại screen_view cho các Route
      navigatorObservers: [observer], // <-- THÊM DÒNG NÀY để tự động log screen_view
    );
  }
}