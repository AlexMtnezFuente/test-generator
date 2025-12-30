/// Representa una respuesta posible a una pregunta.
class Answer {
  Answer({
    required this.text,
    required this.correct,
  });

  // Texto que ve el usuario
  final String text;

  // Indica si esta respuesta es correcta
  final bool correct;

  /// Construye una Answer desde JSON
  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      text: (json['texto'] ?? '').toString(),
      correct: json['correcta'] == true,
    );
  }
}

/// Representa una pregunta del examen.
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

  /// Construye una Question desde JSON
  factory Question.fromJson(Map<String, dynamic> json) {
    List<dynamic> rawAnswers = json['respuestas'] as List<dynamic>? ?? <dynamic>[];

    return Question(
      id: (json['id'] as num?)?.toInt() ?? 0,
      question: (json['pregunta'] ?? '').toString(),
      answers: rawAnswers
          .whereType<Map<String, dynamic>>()
          .map<Answer>(Answer.fromJson)
          .toList(),
      explanation: (json['explicacion'] ?? '').toString(),
    );
  }

  /// Devuelve los índices de las respuestas correctas.
  /// Puede haber 0, 1 o varias.
  Set<int> correctIndexes() {
    Set<int> result = <int>{};

    for (int i = 0; i < answers.length; i++) {
      if (answers[i].correct) {
        result.add(i);
      }
    }

    return result;
  }

  /// Valida si la pregunta es usable en un examen.
  bool get isValidForExam {
    return question.trim().isNotEmpty && answers.length >= 2;
  }

  /// Crea una copia de la pregunta modificando solo lo necesario.
  Question copyWith({List<Answer>? answers}) {
    return Question(
      id: id,
      question: question,
      answers: answers ?? this.answers,
      explanation: explanation,
    );
  }
}
