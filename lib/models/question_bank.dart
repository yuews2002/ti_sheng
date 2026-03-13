import 'question.dart';

class QuestionBank {
  final String id;
  final String name;
  final String description;
  final List<Question> questions;
  final DateTime createdAt;
  final DateTime? updatedAt;

  QuestionBank({
    required this.id,
    required this.name,
    required this.description,
    required this.questions,
    required this.createdAt,
    this.updatedAt,
  });

  int get totalQuestions => questions.length;
  int get answeredQuestions => questions.where((q) => q.isAnswered).length;
  int get correctQuestions => questions.where((q) => q.isCorrect).length;
  double get accuracy {
    if (answeredQuestions == 0) return 0.0;
    return correctQuestions / answeredQuestions;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'questions': questions.map((question) => question.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory QuestionBank.fromMap(Map<String, dynamic> map) {
    return QuestionBank(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      questions: (map['questions'] as List).map((question) => Question.fromMap(question)).toList(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  QuestionBank copyWith({
    String? id,
    String? name,
    String? description,
    List<Question>? questions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuestionBank(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
