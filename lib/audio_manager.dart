import 'package:just_audio/just_audio.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  final AudioPlayer _player = AudioPlayer();

  AudioManager._internal();

  Future<void> playBackgroundMusic() async {
    try {
      await _player.setAsset('assets/audio/nhacnen1.mp3');
      _player.setLoopMode(LoopMode.one);
      _player.play();
    } catch (e) {
      print('Error playing background music: $e');
    }
  }

  void stopBackgroundMusic() {
    _player.stop();
  }

  void pauseBackgroundMusic() {
    _player.pause();
  }

  void resumeBackgroundMusic() {
    _player.play();
  }
} 