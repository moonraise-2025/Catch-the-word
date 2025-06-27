import 'package:just_audio/just_audio.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer(); //am thanh ngawns


  AudioManager._internal();

  Future<void> playBackgroundMusic() async {
    if (_player.playing) return;
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

  bool get isPlaying => _player.playing;


  // Âm thanh nhận quà
  Future<void> playGiftSound() async {
    try {
      await _sfxPlayer.setAsset('assets/audio/nhanthuong.mp3');
      _sfxPlayer.play();
    } catch (e) {
      print('Error playing gift sound: $e');
    }
  }

  // Phát âm thanh khi qua màn
  Future<void> playNextLevelSound() async {
    try {
      await _sfxPlayer.setAsset('audio/quaman.mp3');
      _sfxPlayer.play();
    } catch (e) {
      print('Error playing next level sound: $e');
    }
  }

} 