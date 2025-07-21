import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();

  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Phương thức để log sự kiện xem màn hình Home
  Future<void> logHomeScreen() async {
    await _analytics.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': 'Home',
        'screen_class': 'StartScreen',
      },
    );
    print('Logged Home Screen to Firebase Analytics');
  }

  // Phương thức để log sự kiện xem Level của màn game voơi Level (param: {level_id: number}
  Future<void> logLevelScreen(int levelId) async {
    await _analytics.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': 'Level',
        'screen_class': 'GameScreen',
        'level_id': levelId,
      },
    );
    print('Logged Level Screen with level_id: $levelId to Firebase Analytics');
  }

  // // Bạn có thể thêm các phương thức ghi log sự kiện khác ở đây
  // Future<void> logGameStart(int level) async {
  //   await _analytics.logEvent(
  //     name: 'game_start',
  //     parameters: {
  //       'level_number': level,
  //     },
  //   );
  //   print('Logged game_start for level: $level');
  // }
  //
  // Future<void> logAnswerCorrect(int level, String answer) async {
  //   await _analytics.logEvent(
  //     name: 'answer_correct',
  //     parameters: {
  //       'level_number': level,
  //       'correct_answer': answer,
  //     },
  //   );
  //   print('Logged correct answer for level $level: $answer');
  // }
}
