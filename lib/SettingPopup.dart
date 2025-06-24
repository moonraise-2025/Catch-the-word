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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
              height: 800,
              width: screenWidth * 0.80,
              margin: const EdgeInsets.only(top: 200), // để chừa chỗ cho tiêu đề
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30), // padding cân trái/phải
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
                        style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Color(0xFF8E61DC)),
                      ),
                      const SizedBox(height: 50),
                  Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 140), // 👈 thêm padding 2 bên
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Nhạc Nền',
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(width: 50),
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
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue, width: 3),
                              ),
                              child: Center(
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 200),
                                  scale: _isMusicOn ? 1.0 : 0.0,
                                  curve: Curves.easeOutBack,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF8E61DC),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ),
                      const SizedBox(height: 20),
                      Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 140), // 👈 thêm padding 2 bên
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Rung',
                              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(width: 50),
                          GestureDetector(
                            onTap: () async {
                              await _playTickSound(); // 👈 phát âm tick
                              setState(() {
                                _isSoundEffectOn = !_isSoundEffectOn;
                              });
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue, width: 3),
                              ),
                              child: Center(
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 200),
                                  scale: _isSoundEffectOn ? 1.0 : 0.0, // to dần khi bật, nhỏ dần khi tắt
                                  curve: Curves.easeInOut,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF8E61DC),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                ),
                      const SizedBox(height: 30),

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
                        onPressed: (){},
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
            top: -600,
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/logo.png',
                width: 500,
              ),
            ),
          ),
          // Nút đóng ở góc phải trên
          Positioned(
            top: 100,
            right: 10,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset(
                'assets/images/icon_close.png',
                width: 40,
                height: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
