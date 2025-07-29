import 'package:just_audio/just_audio.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer(); //am thanh ngawns


  AudioManager._internal();

  // Thêm tham số 'volume' cho nhạc nền
  Future<void> playBackgroundMusic({double volume = 0.5}) async {
    if (_player.playing) return;
    try {
      await _player.setAsset('assets/audio/nhacnen2.mp3');
      _player.setLoopMode(LoopMode.one);
      await _player.setVolume(volume.clamp(0.0, 1.0)); // Đặt âm lượng mặc định
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

  // Phương thức để điều chỉnh âm lượng nhạc nền sau khi đã phát
  Future<void> setBackgroundMusicVolume(double volume) async {
    double clampedVolume = volume.clamp(0.0, 1.0);
    await _player.setVolume(clampedVolume);
  }


  // Âm thanh nhận quà (có thêm tham số volume)
  Future<void> playGiftSound({double volume = 1.0}) async {
    try {
      await _sfxPlayer.setAsset('assets/audio/nhanthuong.mp3');
      await _sfxPlayer.setVolume(volume.clamp(0.0, 1.0)); // Đặt âm lượng cho hiệu ứng
      _sfxPlayer.play();
    } catch (e) {
      print('Error playing gift sound: $e');
    }
  }

  // Phát âm thanh khi qua màn (có thêm tham số volume)
  Future<void> playNextLevelSound({double volume = 1.0}) async {
    try {
      await _sfxPlayer.setAsset('assets/audio/popupanswercorrect.mp3');
      await _sfxPlayer.setVolume(volume.clamp(0.0, 1.0)); // Đặt âm lượng cho hiệu ứng
      _sfxPlayer.play();
    } catch (e) {
      print('Error playing next level sound: $e');
    }
  }

}