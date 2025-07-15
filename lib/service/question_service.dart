import 'dart:convert';
import 'package:duoihinhbatchu/model/question.dart';
import 'package:flutter/services.dart' show rootBundle;

class QuestionService {
  static Future<List<Question>> loadQuestions() async {
    try {
      // Đọc nội dung file JSON từ assets
      final String response = await rootBundle.loadString('assets/questions.json');

      // Giải mã chuỗi JSON thành List<dynamic>
      final List<dynamic> data = json.decode(response);

      // Chuyển đổi List<dynamic> thành List<Question> bằng cách sử dụng factory constructor
      return data.map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      print('Error loading questions from JSON: $e');
      // Trả về danh sách rỗng nếu có lỗi
      return [];
    }
  }
}

