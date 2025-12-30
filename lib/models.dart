class Answer {
  Answer({required this.text, required this.correct});

  final String text;
  final bool correct;

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      text: (json['texto'] ?? '').toString(),
      correct: json['correcta'] == true,
    );
  }
}

class Question {
  Question({
    required this.id,
    required this.question,
    required this.answers,
    required this.explanation,
  });

  final int id;
  final String question;
  final List<Answer> answers;
  final String explanation;

  factory Question.fromJson(Map<String, dynamic> json) {
    List<dynamic> raw = json['respuestas'] as List<dynamic>? ?? <dynamic>[];

    return Question(
      id: (json['id'] as num?)?.toInt() ?? 0,
      question: (json['pregunta'] ?? '').toString(),
      answers: raw
          .whereType<Map<String, dynamic>>()
          .map<Answer>(Answer.fromJson)
          .toList(),
      explanation: (json['explicacion'] ?? '').toString(),
    );
  }

  Question copyWith({List<Answer>? answers}) {
    return Question(
      id: id,
      question: question,
      answers: answers ?? this.answers,
      explanation: explanation,
    );
  }
}
