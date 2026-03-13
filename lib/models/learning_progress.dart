class LearningProgress {
  final String id;
  final String questionBankId;
  final int totalQuestions;
  final int answeredQuestions;
  final int correctQuestions;
  final List<String> wrongQuestionIds;
  final DateTime lastStudiedAt;
  final DateTime createdAt;
  final int currentQuestionIndex; // 当前练习进度

  LearningProgress({
    required this.id,
    required this.questionBankId,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.correctQuestions,
    required this.wrongQuestionIds,
    required this.lastStudiedAt,
    required this.createdAt,
    this.currentQuestionIndex = 0,
  });

  double get accuracy {
    if (answeredQuestions == 0) return 0.0;
    return correctQuestions / answeredQuestions;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionBankId': questionBankId,
      'totalQuestions': totalQuestions,
      'answeredQuestions': answeredQuestions,
      'correctQuestions': correctQuestions,
      'wrongQuestionIds': wrongQuestionIds,
      'lastStudiedAt': lastStudiedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'currentQuestionIndex': currentQuestionIndex,
    };
  }

  factory LearningProgress.fromMap(Map<String, dynamic> map) {
    return LearningProgress(
      id: map['id'],
      questionBankId: map['questionBankId'],
      totalQuestions: map['totalQuestions'],
      answeredQuestions: map['answeredQuestions'],
      correctQuestions: map['correctQuestions'],
      wrongQuestionIds: List<String>.from(map['wrongQuestionIds']),
      lastStudiedAt: DateTime.parse(map['lastStudiedAt']),
      createdAt: DateTime.parse(map['createdAt']),
      currentQuestionIndex: map['currentQuestionIndex'] ?? 0,
    );
  }

  LearningProgress copyWith({
    String? id,
    String? questionBankId,
    int? totalQuestions,
    int? answeredQuestions,
    int? correctQuestions,
    List<String>? wrongQuestionIds,
    DateTime? lastStudiedAt,
    DateTime? createdAt,
    int? currentQuestionIndex,
  }) {
    return LearningProgress(
      id: id ?? this.id,
      questionBankId: questionBankId ?? this.questionBankId,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      answeredQuestions: answeredQuestions ?? this.answeredQuestions,
      correctQuestions: correctQuestions ?? this.correctQuestions,
      wrongQuestionIds: wrongQuestionIds ?? this.wrongQuestionIds,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
      createdAt: createdAt ?? this.createdAt,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    );
  }
}
