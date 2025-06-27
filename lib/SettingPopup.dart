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
  bool _isPressed = false;

  final AudioPlayer _player = AudioPlayer();

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
      _isPressed = isDown;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
        backgroundColor: Colors.transparent,
        // Sử dụng ConstrainedBox để đặt kích thước tối đa cho nội dung popup.
        // Điều này giúp popup không quá lớn trên màn hình rộng (ví dụ: máy tính bảng).
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenWidth * 0.9, // Chiều rộng tối đa 90% màn hình
            maxHeight: screenHeight * 0.6, // Chiều cao tối đa 90% màn hình
          ),
          child: Stack(
            children: [
              Container(// Điều chỉnh chiều cao và chiều rộng dựa trên kích thước màn hình

                  height: screenHeight * 0.7,// Chiếm 70% chiều cao màn hình
                  width: screenWidth * 0.85, // Chiếm 85% chiều rộng màn hình
                  margin: EdgeInsets.only(top: screenHeight * 0.1), // Margin động để chừa chỗ cho tiêu đề/logo
                  padding: EdgeInsets.symmetric(// Padding cân đối dựa trên kích thước màn hình
                    horizontal: screenWidth * 0.05,// 5% chiều rộng màn hình cho padding ngang
                    vertical: screenHeight *0.03 // 3% chiều cao màn hình cho padding dọc,
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
                                fontSize: screenWidth * 0.08,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF8E61DC)),
                          ),
                           SizedBox(height: screenHeight *0.01 ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.1),
                            // 👈 thêm padding 2 bên
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Nhạc Nền',
                                    style: TextStyle(
                                        fontSize: screenWidth * 0.05,
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
                                    width: screenWidth * 0.08,
                                    height: screenWidth * 0.08,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          screenWidth * 0.02),
                                      border: Border.all(
                                          color: Colors.blue, width: 3),
                                    ),
                                    child: Center(
                                      child: AnimatedScale(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        scale: _isMusicOn ? 1.0 : 0.0,
                                        curve: Curves.easeOutBack,
                                        child: Container(
                                          width: screenWidth * 0.05,
                                          height: screenWidth * 0.05,
                                          decoration: BoxDecoration(
                                            color: Color(0xFF8E61DC),
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
                                horizontal: screenWidth * 0.1),
                            // 👈 thêm padding 2 bên
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Rung',
                                    style: TextStyle(
                                        fontSize: screenWidth * 0.05,
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
                                    width: screenWidth * 0.08,
                                    height: screenWidth * 0.08,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          screenWidth * 0.02),
                                      border: Border.all(
                                          color: Colors.blue, width: 3),
                                    ),
                                    child: Center(
                                      child: AnimatedScale(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        scale: _isSoundEffectOn ? 1.0 : 0.0,
                                        // to dần khi bật, nhỏ dần khi tắt
                                        curve: Curves.easeInOut,
                                        child: Container(
                                          width: screenWidth * 0.05,
                                          height: screenWidth * 0.05,
                                          decoration: BoxDecoration(
                                            color: Color(0xFF8E61DC),
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

                          // Center(
                          //   child: GestureDetector(
                          //     onTapDown: (_) => _handlePress(true),
                          //     onTapUp: (_) => _handlePress(false),
                          //     onTapCancel: () => _handlePress(false),
                          //   child: ElevatedButton(
                          //     onPressed: () {
                          //
                          //     },
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: _isPressed ? const Color(0xFF8E61DC) : Colors.white,
                          //       foregroundColor: _isPressed ? Colors.white : const Color(0xFF8E61DC),
                          //       padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 25), // 👈 Tăng padding
                          //       minimumSize: const Size(350, 80),
                          //       textStyle: const TextStyle(
                          //         fontSize: 40,
                          //         fontWeight: FontWeight.bold, ),
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(10),
                          //       ),
                          //     ),
                          //     child: const Text('Đánh giá'),
                          //   ),
                          // )
                          // ),
                          AnimatedButton(
                            text: 'Đánh giá',
                            onPressed: () {},
                          )
                        ],
                      ),
                    ),
                  )),
              // Positioned(
              //   top: -30,
              //   left: 20,
              //   child: Container(
              //     padding: const EdgeInsets.all(10),
              //     decoration: BoxDecoration(
              //       color: Colors.white,
              //       borderRadius: BorderRadius.circular(50),
              //       border: Border.all(color: Colors.blueAccent, width: 3),
              //     ),
              //     child: const Icon(Icons.settings,
              //         size: 50, color: Colors.blueAccent),
              //   ),
              // ),

              Positioned(
                top: screenHeight * 0.02, // Điều chỉnh giá trị này cẩn thận
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: screenWidth *
                        0.7, // Chiều rộng logo theo chiều rộng màn hình
                  ),
                ),
              ),
              // Nút đóng ở góc phải trên
              Positioned(
                top: screenHeight * 0.05, // Vị trí theo chiều cao màn hình
                right: screenWidth * 0.02, // Vị trí theo chiều rộng màn hình
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Image.asset(
                    'assets/images/icon_close.png',
                    width: screenWidth * 0.06,
                    // Kích thước theo chiều rộng màn hình
                    height: screenWidth *
                        0.06, // Kích thước theo chiều rộng màn hình
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
