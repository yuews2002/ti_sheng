import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'question.dart';

class ExamResult {
  final String id;
  final String questionBankId;
  final DateTime examTime;
  final int totalQuestions;
  final int correctQuestions;
  final int wrongQuestions;
  final List<String> wrongQuestionIds;
  final double score;

  ExamResult({
    required this.id,
    required this.questionBankId,
    required this.examTime,
    required this.totalQuestions,
    required this.correctQuestions,
    required this.wrongQuestions,
    required this.wrongQuestionIds,
    required this.score,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionBankId': questionBankId,
      'examTime': examTime.toIso8601String(),
      'totalQuestions': totalQuestions,
      'correctQuestions': correctQuestions,
      'wrongQuestions': wrongQuestions,
      'wrongQuestionIds': wrongQuestionIds,
      'score': score,
    };
  }

  factory ExamResult.fromMap(Map<String, dynamic> map) {
    return ExamResult(
      id: map['id'] ?? '',
      questionBankId: map['questionBankId'] ?? '',
      examTime: DateTime.parse(map['examTime']),
      totalQuestions: map['totalQuestions'] ?? 0,
      correctQuestions: map['correctQuestions'] ?? 0,
      wrongQuestions: map['wrongQuestions'] ?? 0,
      wrongQuestionIds: List<String>.from(map['wrongQuestionIds'] ?? []),
      score: map['score'] ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ExamResult.fromJson(String source) => ExamResult.fromMap(json.decode(source));
}
