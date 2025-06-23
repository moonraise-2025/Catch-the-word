import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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

  Future<void> _playTickSound() async {
    try {
      await _player.play(AssetSource('tick.mp3'), volume: 0.3); //  phát tick
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none, 
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 20), 
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30), 
              border: Border.all(color: Colors.blueAccent, width: 5), 
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Nhạc Nền', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10), 
                        GestureDetector(
                          onTap: () async {
                            await _playTickSound(); // 👈 phát âm tick
                            setState(() {
                              _isMusicOn = !_isMusicOn;
                              if (_isMusicOn) {
                                AudioManager().playBackgroundMusic();
                              } else {
                                AudioManager().stopBackgroundMusic();
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 50,
                            width: 100, 
                            decoration: BoxDecoration(
                              color: _isMusicOn ? Colors.lightGreen : Colors.grey[300], 
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.black26, width: 2),
                            ),
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeIn,
                                  left: _isMusicOn ? 50 : 0, 
                                  child: Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white, 
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(Icons.music_note, color: _isMusicOn ? Colors.lightGreen : Colors.grey, size: 30), // Icon nhạc
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Rung', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () async {
                            await _playTickSound(); // 👈 phát âm tick
                            setState(() {
                              _isSoundEffectOn = !_isSoundEffectOn;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 50,
                            width: 100,
                            decoration: BoxDecoration(
                              color: _isSoundEffectOn ? Colors.lightGreen : Colors.grey[300],
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.black26, width: 2),
                            ),
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeIn,
                                  left: _isSoundEffectOn ? 50 : 0,
                                  child: Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(Icons.volume_up, color: _isSoundEffectOn ? Colors.lightGreen : Colors.grey, size: 30),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Đánh Giá'),
                ),
              ],
            ),
          ),
          Positioned(
            top: -30, 
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50), 
                border: Border.all(color: Colors.blueAccent, width: 3),
              ),
              child: const Icon(Icons.settings, size: 50, color: Colors.blueAccent),
            ),
          ),
          Positioned(
            top: -15, 
            left: 0,
            right: 0,
            child: Container(
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.pinkAccent, 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.pink, width: 2), 
              ),
              child: Text(
                'Cài Đặt',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, size: 30, color: Colors.blueAccent),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
} 