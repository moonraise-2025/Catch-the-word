import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Thêm import này
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Thêm import này
import 'GameScreen.dart';
import 'SettingPopup.dart';
import 'InfoPopup.dart';
import 'ads/banner_ad_provider.dart';
import 'audio_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_analysis/analytics_service.dart';

// Thay đổi từ StatefulWidget thành ConsumerStatefulWidget
class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState(); // Thay đổi ở đây
}

// Thay đổi từ State thành ConsumerState
class _StartScreenState extends ConsumerState<StartScreen> with SingleTickerProviderStateMixin {
  int? lastLevel;
  bool loading = true;
  Map<String, bool> _isPressedMap = {};
  late AnimationController _animationController;
  bool _isAnimationInitialized = false;

  @override
  void initState() {
    super.initState();
    print('initState: Bắt đầu khởi tạo StartScreen');
    AnalyticsService().logHomeScreen();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _isAnimationInitialized = true;
    print('initState: Animation đã được khởi tạo. Gọi _loadInitialDataAndAnimate.');
    _loadInitialDataAndAnimate();

    // Thêm đoạn code tải banner ad
    // Đảm bảo context đã sẵn sàng để tính toán kích thước banner thích ứng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('initState: Calling createAnchoredBanner.');
      ref.read(bannerAdProvider.notifier).createAnchoredBanner(context); // Tải banner ad
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    print('dispose: AnimationController đã được giải phóng.');
    // Giải phóng tài nguyên banner ad khi màn hình bị loại bỏ
    ref.read(bannerAdProvider.notifier).disposeBannerAd(); // Giải phóng banner ad
    super.dispose();
  }

  Future<void> _loadInitialDataAndAnimate() async {
    print('_loadInitialDataAndAnimate: Bắt đầu tải dữ liệu.');
    try {
      print('_loadInitialDataAndAnimate: Đang chờ SharedPreferences.getInstance()...');
      final prefs = await SharedPreferences.getInstance();
      print('_loadInitialDataAndAnimate: Đã lấy được SharedPreferences instance.');
      if (mounted) {
        setState(() {
          lastLevel = prefs.getInt('lastLevel');
          loading = false;
          print('_loadInitialDataAndAnimate: lastLevel = $lastLevel, loading = false.');
        });
        // THAY ĐỔI QUAN TRỌNG TẠI ĐÂY:
        _animationController.reset(); // Đặt lại animation về trạng thái ban đầu
        _animationController.forward(); // Phát lại animation
        print('_loadInitialDataAndAnimate: Animation đã bắt đầu.');
      } else {
        print('_loadInitialDataAndAnimate: Widget không còn mounted.');
      }
    } catch (e) {
      print('Error loading SharedPreferences: $e');
      if (mounted) {
        setState(() {
          loading = false;
          lastLevel = null;
        });
      }
    }
  }

  void _startNewGame() async {
    print('_startNewGame: Bắt đầu trò chơi mới.');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastLevel', 1);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    );
    // Khi quay lại từ GameScreen, gọi lại hàm này để tải lại dữ liệu và chạy animation
    _loadInitialDataAndAnimate();
    // Tải lại banner ad (nếu cần thiết, hoặc AdMob sẽ tự động làm nếu đã dispose)
    // ref.read(bannerAdProvider.notifier).createAnchoredBanner(context);
  }

  void _continueGame() async {
    print('_continueGame: Tiếp tục trò chơi.');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          initialLevel: lastLevel ?? 1,
        ),
      ),
    );
    // Khi quay lại từ GameScreen, gọi lại hàm này để tải lại dữ liệu và chạy animation
    _loadInitialDataAndAnimate();
    // Tải lại banner ad (nếu cần thiết, hoặc AdMob sẽ tự động làm nếu đã dispose)
    // ref.read(bannerAdProvider.notifier).createAnchoredBanner(context);
  }

  @override
  Widget build(BuildContext context) {
    if (loading || !_isAnimationInitialized) {
      print('build: Đang hiển thị CircularProgressIndicator (loading: $loading, _isAnimationInitialized: $_isAnimationInitialized)');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    print('build: Đã tải xong, hiển thị UI chính.');
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final double buttonWidth = screenWidth * 0.7;
    final double buttonHeight = screenHeight * 0.06;
    return Scaffold(
      body: Builder(
        builder: (context) {
          return Container(
            width: screenWidth,
            height: screenHeight,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/BackgroundDHBC.png'),
                fit: BoxFit.cover,
                repeat: ImageRepeat.noRepeat,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.08),
                        child: Image.asset( // Removed SlideTransition
                          'assets/images/logodhbc.png',
                          width: screenWidth * 0.8,
                          height: screenHeight * 0.25,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.15),
                      if (lastLevel == null || lastLevel == 1) ...[
                        AnimatedScale( // Removed SlideTransition
                          scale: _isPressedMap['start_game'] == true ? 0.95 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: GestureDetector(
                            onTapDown: (_) => setState(() => _isPressedMap['start_game'] = true),
                            onTapUp: (_) {
                              setState(() => _isPressedMap['start_game'] = false);
                              _startNewGame();
                            },
                            onTapCancel: () => setState(() => _isPressedMap['start_game'] = false),
                            child: SizedBox(
                              width: buttonWidth,
                              height: buttonHeight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue,
                                  textStyle: TextStyle(
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _startNewGame,
                                child: const Text('Chơi ngay', textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        AnimatedScale( // Removed SlideTransition
                          scale: _isPressedMap['continue_game'] == true ? 0.95 : 1.0,
                          duration: const Duration(milliseconds: 100),
                          child: GestureDetector(
                            onTapDown: (_) => setState(() => _isPressedMap['continue_game'] = true),
                            onTapUp: (_) {
                              setState(() => _isPressedMap['continue_game'] = false);
                              _continueGame();
                            },
                            onTapCancel: () => setState(() => _isPressedMap['continue_game'] = false),
                            child: SizedBox(
                              width: buttonWidth,
                              height: buttonHeight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF616FD3),
                                  textStyle: TextStyle(
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _continueGame,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('TIẾP TỤC', textAlign: TextAlign.center),
                                    Text('(Level $lastLevel)',
                                        style: TextStyle(
                                            fontSize: screenWidth * 0.03,
                                            color: const Color(0xFF4E4E51))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: screenHeight * 0.08),
                    ],
                  ),
                ),

                Positioned(
                  top: screenHeight * 0.055,
                  right: screenWidth * 0.04,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: false,
                            barrierLabel: 'InfoPopup',
                            barrierColor: Colors.black.withOpacity(0.5),
                            transitionDuration: const Duration(milliseconds: 300),
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return const InfoPopup();
                            },
                            transitionBuilder: (context, animation, secondaryAnimation, child) {
                              // Animation khi hiển thị: (0, 0.8) -> (1, 1.05) -> (1, 1.0)
                              // Animation khi ẩn: (1, 1.0) -> (1, 1.05) -> (0, 0.8)

                              final opacityTween = TweenSequence<double>([
                                TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 0.7), // Hiện rõ 70% thời gian đầu
                                TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 0.3), // Giữ nguyên 100% opacity 30% thời gian sau
                              ]);

                              final scaleTween = TweenSequence<double>([
                                TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 1.05), weight: 0.7), // Phóng to từ 0.8 lên 1.05 trong 70% thời gian đầu
                                TweenSequenceItem(tween: Tween<double>(begin: 1.05, end: 1.0), weight: 0.3), // Thu nhỏ từ 1.05 về 1.0 trong 30% thời gian sau
                              ]);

                              return ScaleTransition(
                                scale: scaleTween.animate(animation),
                                child: FadeTransition(
                                  opacity: opacityTween.animate(animation),
                                  child: child,
                                ),
                              );
                            },
                          );
                        },
                        child: Image.asset(
                          'assets/images/thongtin.png',
                          width: screenWidth * 0.07,
                          height: screenWidth * 0.07,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      GestureDetector(
                        onTap: () {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: false,
                            barrierLabel: 'SettingPopup',
                            barrierColor: Colors.black.withOpacity(0.5),
                            transitionDuration: const Duration(milliseconds: 300),
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return const SettingPopup();
                            },
                            transitionBuilder: (context, animation, secondaryAnimation, child) {

                              final opacityTween = TweenSequence<double>([
                                TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 0.7),
                                TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 0.3),
                              ]);

                              final scaleTween = TweenSequence<double>([
                                TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 1.05), weight: 0.7),
                                TweenSequenceItem(tween: Tween<double>(begin: 1.05, end: 1.0), weight: 0.3),
                              ]);

                              return ScaleTransition(
                                scale: scaleTween.animate(animation),
                                child: FadeTransition(
                                  opacity: opacityTween.animate(animation),
                                  child: child,
                                ),
                              );
                            },
                          );
                        },
                        child: Image.asset(
                          'assets/images/setting.png',
                          width: screenWidth * 0.07,
                          height: screenWidth * 0.07,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
                // Thêm widget banner ad ở dưới cùng
                Align(
                  alignment: Alignment.bottomCenter,
                  child: getBanner(context, ref), //
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}