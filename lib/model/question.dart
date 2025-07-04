class Question {
  final String id;
  final String imgQuestion;
  final String answer;
  final String answerType;

  Question({
    required this.id,
    required this.imgQuestion,
    required this.answer,
    required this.answerType,
  });

  // Factory constructor để tạo một đối tượng Question từ Map (JSON)
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      imgQuestion: json['img_question'] as String,
      answer: json['answer'] as String,
      answerType: json['answer_type'] as String,
    );
  }

  // Phương thức tùy chọn để chuyển đổi đối tượng Question thành Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'img_question': imgQuestion,
      'answer': answer,
      'answer_type': answerType,
    };
  }
}