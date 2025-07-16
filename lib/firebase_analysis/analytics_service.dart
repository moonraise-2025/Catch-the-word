import 'package:firebase_analytics/firebase_analytics.dart';

// Đây là một Singleton Pattern để đảm bảo chỉ có một thể hiện của lớp này.
class AnalyticsService {
  // Thể hiện duy nhất của lớp
  static final AnalyticsService _instance = AnalyticsService._internal();

  // Factory constructor để trả về thể hiện duy nhất
  factory AnalyticsService() {
    return _instance;
  }

  // Private constructor để ngăn tạo thể hiện mới bên ngoài
  AnalyticsService._internal();

  // Khởi tạo FirebaseAnalytics instance
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Phương thức để log sự kiện xem màn hình Home
  Future<void> logHomeScreen() async {
    await _analytics.logEvent(
      name: 'screen_view', // Đã sửa từ FirebaseAnalytics.Event.SCREEN_VIEW
      parameters: {
        'screen_name': 'Home', // Đã sửa từ FirebaseAnalytics.Param.SCREEN_NAME
        'screen_class': 'StartScreen', // Đã sửa từ FirebaseAnalytics.Param.SCREEN_CLASS
      },
    );
    print('Logged Home Screen to Firebase Analytics');
  }

  // Phương thức để log sự kiện xem màn hình Level với level_id
  Future<void> logLevelScreen(int levelId) async {
    await _analytics.logEvent(
      name: 'screen_view',
      parameters: {
        'screen_name': 'Level',
        'screen_class': 'GameScreen',
        'level_id': levelId, // Tham số tùy chỉnh của bạn vẫn giữ nguyên
      },
    );
    print('Logged Level Screen with level_id: $levelId to Firebase Analytics');
  }

  // Bạn có thể thêm các phương thức ghi log sự kiện khác ở đây
  Future<void> logGameStart(int level) async {
    await _analytics.logEvent(
      name: 'game_start',
      parameters: {
        'level_number': level,
      },
    );
    print('Logged game_start for level: $level');
  }

  Future<void> logAnswerCorrect(int level, String answer) async {
    await _analytics.logEvent(
      name: 'answer_correct',
      parameters: {
        'level_number': level,
        'correct_answer': answer,
      },
    );
    print('Logged correct answer for level $level: $answer');
  }
}
