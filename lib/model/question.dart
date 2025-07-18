class Question {
  final String id;
  final String answer;
  final String? answerType;

  Question({
    required this.id,
    required this.answer,
    required this.answerType,
  });

  String get imgQuestion =>
      'https://moonraise-2025.github.io/dhbc/images-v1/$id.png';

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      answer: json['answer'] as String,
      answerType: json['answer_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'answer': answer,
      'answer_type': answerType,
    };
  }
}
