class Question {
  final String id;
  final String content;
  final QuestionType type;
  final List<Option> options;
  final List<String> correctAnswers;
  final String explanation;
  bool isAnswered;
  List<String> userAnswers;
  int errorCount; // 错误次数

  Question({
    required this.id,
    required this.content,
    required this.type,
    required this.options,
    required this.correctAnswers,
    required this.explanation,
    this.isAnswered = false,
    this.userAnswers = const [],
    this.errorCount = 0,
  });

  bool get isCorrect {
    if (userAnswers.isEmpty) return false;
    if (type == QuestionType.singleChoice) {
      return userAnswers.first == correctAnswers.first;
    } else {
      if (userAnswers.length != correctAnswers.length) return false;
      return userAnswers.every((answer) => correctAnswers.contains(answer));
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'type': type.index,
      'options': options.map((option) => option.toMap()).toList(),
      'correctAnswers': correctAnswers,
      'explanation': explanation,
      'errorCount': errorCount,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      content: map['content'],
      type: QuestionType.values[map['type']],
      options: (map['options'] as List).map((option) => Option.fromMap(option)).toList(),
      correctAnswers: List<String>.from(map['correctAnswers']),
      explanation: map['explanation'],
      errorCount: map['errorCount'] ?? 0,
    );
  }
}

class Option {
  final String id;
  final String content;

  Option({
    required this.id,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
    };
  }

  factory Option.fromMap(Map<String, dynamic> map) {
    return Option(
      id: map['id'],
      content: map['content'],
    );
  }
}

enum QuestionType {
  singleChoice,
  multipleChoice,
}
