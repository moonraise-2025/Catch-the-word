import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'AnimatedButton.dart';
import 'audio_manager.dart';

class SettingPopup extends StatefulWidget {
  const SettingPopup({super.key});

  @override
  State<SettingPopup> createState() => _SettingPopupState();
}

class _SettingPopupState extends State<SettingPopup> {
  bool _isMusicOn = true;
  bool _isSoundEffectOn = true;

  final AudioPlayer _player = AudioPlayer();

  bool _isRatingButtonPressed = false;

  Future<void> _playTickSound() async {
    try {
      await _player.play(AssetSource('audio/tick.mp3'),
          volume: 0.3); //  phát tick
    } catch (e) {
      debugPrint('Lỗi phát âm thanh: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose(); // giải phóng tài nguyên
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isMusicOn = AudioManager().isPlaying;
  }

  void _handlePress(bool isDown) {
    setState(() {
      //_isPressed = isDown; // Dòng này không còn dùng
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Center(
      child: Stack(
        children: [
          Container(
              width: screenWidth * 0.90,
              height: screenHeight * 0.50,
              margin: EdgeInsets.only(top: screenHeight * 0.1), // Margin động để chừa chỗ cho tiêu đề/logo
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenHeight * 0.025,
              ),
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/bg_popup.png'),
                  fit: BoxFit.fill,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Cài Đặt ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: screenWidth * 0.1,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF626DD2)),
                      ),
                      SizedBox(height: screenHeight *0.01 ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.18),
                        // 👈 thêm padding 2 bên
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Nhạc nền',
                                style: TextStyle(
                                    fontSize: screenWidth * 0.06,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            SizedBox(width: screenWidth * 0.04),
                            GestureDetector(
                              onTap: () async {
                                await _playTickSound();
                                setState(() {
                                  _isMusicOn = !_isMusicOn;
                                  if (_isMusicOn) {
                                    AudioManager().playBackgroundMusic();
                                  } else {
                                    AudioManager().stopBackgroundMusic();
                                  }
                                });
                              },
                              child: Container(
                                width: screenWidth * 0.12,
                                height: screenWidth * 0.12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      screenWidth * 0.02),

                                ),
                                child: Center(
                                  child: AnimatedScale(
                                    duration:
                                    const Duration(milliseconds: 200),
                                    scale: _isMusicOn ? 1.0 : 0.0,
                                    curve: Curves.easeOutBack,
                                    child: Container(
                                      width: screenWidth * 0.1,
                                      height: screenWidth * 0.1,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF626DD2),
                                        borderRadius: BorderRadius.circular(
                                            screenWidth * 0.01),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Rung',
                                style: TextStyle(
                                    fontSize: screenWidth * 0.06,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            SizedBox(width: screenWidth * 0.04),
                            GestureDetector(
                              onTap: () async {
                                await _playTickSound(); // 👈 phát âm tick
                                setState(() {
                                  _isSoundEffectOn = !_isSoundEffectOn;
                                });
                              },
                              child: Container(
                                width: screenWidth * 0.12,
                                height: screenWidth * 0.12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      screenWidth * 0.02),

                                ),
                                child: Center(
                                  child: AnimatedScale(
                                    duration:
                                    const Duration(milliseconds: 200),
                                    scale: _isSoundEffectOn ? 1.0 : 0.0,
                                    // to dần khi bật, nhỏ dần khi tắt
                                    curve: Curves.easeInOut,
                                    child: Container(
                                      width: screenWidth * 0.1,
                                      height: screenWidth * 0.1,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF626DD2),
                                        borderRadius: BorderRadius.circular(
                                            screenWidth * 0.01),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Phần nút "Đánh giá" đã được thêm hiệu ứng phóng to/thu nhỏ
                      AnimatedScale(
                        scale: _isRatingButtonPressed ? 0.95 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: GestureDetector(
                          onTapDown: (_) => setState(() => _isRatingButtonPressed = true),
                          onTapUp: (_) {
                            setState(() {
                              _isRatingButtonPressed = false; // Đặt lại trạng thái không nhấn
                            });
                          },
                          onTapCancel: () => setState(() => _isRatingButtonPressed = false),
                          child: AnimatedButton( // Giữ nguyên AnimatedButton bên trong
                            text: 'Đánh giá',
                            onPressed: () {
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              )

          ),
          Positioned(
            top: screenHeight * 0.02, // Điều chỉnh giá trị này cẩn thận
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/logo.png',
                width: screenWidth * 0.7,
              ),
            ),
          ),
          // Nút đóng ở góc phải trên
          Positioned(
            top: screenHeight * 0.05,
            right: screenWidth * 0.02,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset(
                'assets/images/icon_close.png',
                width: screenWidth * 0.08,
                height: screenWidth * 0.08,
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.65),

        ],
      ),
    );

  }
}