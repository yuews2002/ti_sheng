import 'package:flutter/foundation.dart';
import '../models/question_bank.dart';
import '../models/learning_progress.dart';
import '../models/question.dart';
import '../models/quiz_mode.dart';
import '../models/exam_result.dart';
import '../utils/storage_service.dart';

class QuizProvider with ChangeNotifier {
  QuestionBank? _currentQuestionBank;
  LearningProgress? _currentProgress;
  QuizMode _currentMode = QuizMode.sequential;
  List<Question> _originalQuestions = [];
  int _currentQuestionIndex = 0;
  bool _isAnswered = false;
  bool _isLoading = false;

  QuestionBank? get currentQuestionBank => _currentQuestionBank;
  LearningProgress? get currentProgress => _currentProgress;
  int get currentQuestionIndex => _currentQuestionIndex;
  bool get isAnswered => _isAnswered;
  bool get isLoading => _isLoading;
  QuizMode get currentMode => _currentMode;
  Question? get currentQuestion {
    if (_currentQuestionBank == null || _currentQuestionBank!.questions.isEmpty) {
      return null;
    }
    return _currentQuestionBank!.questions[_currentQuestionIndex];
  }

  Future<void> loadQuestionBank(String bankId, {QuizMode mode = QuizMode.sequential}) async {
    _isLoading = true;
    _currentMode = mode;
    notifyListeners();

    try {
      // 从存储中加载题库
      final questionBank = await StorageService.loadQuestionBank(bankId);
      if (questionBank != null) {
        _originalQuestions = List.from(questionBank.questions);
        
        // 根据模式处理题目
        List<Question> processedQuestions = [];
        switch (mode) {
          case QuizMode.sequential:
            // 顺序练习，保持原题库顺序
            processedQuestions = List.from(_originalQuestions);
            break;
          case QuizMode.random:
            // 随机练习，随机打乱题目顺序
            processedQuestions = List.from(_originalQuestions)..shuffle();
            break;
          case QuizMode.exam:
            // 模拟考试，随机打乱题目顺序，限制100题
            processedQuestions = List.from(_originalQuestions)..shuffle();
            if (processedQuestions.length > 100) {
              processedQuestions = processedQuestions.sublist(0, 100);
            }
            break;
          case QuizMode.wrongQuestions:
            // 错题练习，只显示错题
            _currentProgress = await StorageService.loadLearningProgress(bankId);
            if (_currentProgress != null && _currentProgress!.wrongQuestionIds.isNotEmpty) {
              processedQuestions = _originalQuestions.where((q) => _currentProgress!.wrongQuestionIds.contains(q.id)).toList();
            } else {
              // 如果没有错题，显示所有题目
              processedQuestions = List.from(_originalQuestions);
            }
            break;
        }
        
        // 创建新的题库，使用处理后的题目
        _currentQuestionBank = QuestionBank(
          id: questionBank.id,
          name: questionBank.name,
          description: questionBank.description,
          questions: processedQuestions,
          createdAt: questionBank.createdAt,
        );
        
        // 加载学习进度
        if (mode == QuizMode.exam) {
          // 考试模式，重新计分，创建新的学习进度
          _currentProgress = LearningProgress(
            id: DateTime.now().toString(),
            questionBankId: bankId,
            totalQuestions: processedQuestions.length,
            answeredQuestions: 0,
            correctQuestions: 0,
            wrongQuestionIds: [],
            lastStudiedAt: DateTime.now(),
            createdAt: DateTime.now(),
          );
        } else {
          // 其他模式，加载现有的学习进度
          _currentProgress = await StorageService.loadLearningProgress(bankId);
          _currentProgress ??= LearningProgress(
            id: DateTime.now().toString(),
            questionBankId: bankId,
            totalQuestions: questionBank.questions.length,
            answeredQuestions: 0,
            correctQuestions: 0,
            wrongQuestionIds: [],
            lastStudiedAt: DateTime.now(),
            createdAt: DateTime.now(),
          );
        }
        
        // 重置当前题目索引
        if (mode == QuizMode.sequential) {
          // 顺序练习，加载保存的进度
          _currentQuestionIndex = _currentProgress?.currentQuestionIndex ?? 0;
        } else {
          // 其他模式，从第一题开始
          _currentQuestionIndex = 0;
        }
        _isAnswered = currentQuestion?.isAnswered ?? false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load question bank: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveQuestionBank(QuestionBank questionBank) async {
    _isLoading = true;
    notifyListeners();

    try {
      await StorageService.saveQuestionBank(questionBank);
      _currentQuestionBank = questionBank;
      // 初始化学习进度
      _currentProgress = LearningProgress(
        id: DateTime.now().toString(),
        questionBankId: questionBank.id,
        totalQuestions: questionBank.questions.length,
        answeredQuestions: 0,
        correctQuestions: 0,
        wrongQuestionIds: [],
        lastStudiedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await StorageService.saveLearningProgress(_currentProgress!);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save question bank: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectAnswer(String optionId) {
    if (currentQuestion == null || _isAnswered) return;

    setState(() {
      if (currentQuestion!.type == QuestionType.singleChoice) {
        currentQuestion!.userAnswers = [optionId];
      } else {
        if (currentQuestion!.userAnswers.contains(optionId)) {
          currentQuestion!.userAnswers.remove(optionId);
        } else {
          currentQuestion!.userAnswers.add(optionId);
        }
      }
    });
  }

  void submitAnswer() {
    if (currentQuestion == null || _isAnswered) return;

    setState(() {
      currentQuestion!.isAnswered = true;
      _isAnswered = true;

      // 更新学习进度
      if (_currentProgress != null) {
        final isCorrect = currentQuestion!.isCorrect;
        final wrongQuestionIds = List<String>.from(_currentProgress!.wrongQuestionIds);

        if (isCorrect) {
          if (wrongQuestionIds.contains(currentQuestion!.id)) {
            wrongQuestionIds.remove(currentQuestion!.id);
          }
        } else {
          if (!wrongQuestionIds.contains(currentQuestion!.id)) {
            wrongQuestionIds.add(currentQuestion!.id);
          }
          // 增加错误次数
          currentQuestion!.errorCount++;
        }

        _currentProgress = _currentProgress!.copyWith(
          answeredQuestions: _currentProgress!.answeredQuestions + 1,
          correctQuestions: isCorrect ? _currentProgress!.correctQuestions + 1 : _currentProgress!.correctQuestions,
          wrongQuestionIds: wrongQuestionIds,
          lastStudiedAt: DateTime.now(),
        );

        // 保存学习进度（考试模式除外，因为考试模式是临时的）
        if (_currentMode != QuizMode.exam) {
          StorageService.saveLearningProgress(_currentProgress!);
        }

        // 考试模式下，检查是否完成考试
        if (_currentMode == QuizMode.exam) {
          bool isExamFinished = true;
          for (var question in _currentQuestionBank!.questions) {
            if (!question.isAnswered) {
              isExamFinished = false;
              break;
            }
          }

          if (isExamFinished) {
            // 计算考试成绩
            int correctCount = 0;
            List<String> wrongIds = [];
            for (var question in _currentQuestionBank!.questions) {
              if (question.isCorrect) {
                correctCount++;
              } else {
                wrongIds.add(question.id);
              }
            }

            double score = (_currentQuestionBank!.questions.length > 0)
                ? (correctCount / _currentQuestionBank!.questions.length) * 100
                : 0;

            // 创建并保存考试成绩
            final examResult = ExamResult(
              id: DateTime.now().toString(),
              questionBankId: _currentQuestionBank!.id,
              examTime: DateTime.now(),
              totalQuestions: _currentQuestionBank!.questions.length,
              correctQuestions: correctCount,
              wrongQuestions: wrongIds.length,
              wrongQuestionIds: wrongIds,
              score: score,
            );

            StorageService.saveExamResult(examResult);
          }
        }
      }
    });
  }

  void nextQuestion() {
    if (_currentQuestionBank == null) return;

    setState(() {
      if (_currentQuestionIndex < _currentQuestionBank!.questions.length - 1) {
        _currentQuestionIndex++;
        _isAnswered = currentQuestion!.isAnswered;

        // 保存顺序练习的进度
        if (_currentMode == QuizMode.sequential && _currentProgress != null) {
          _currentProgress = _currentProgress!.copyWith(
            currentQuestionIndex: _currentQuestionIndex,
            lastStudiedAt: DateTime.now(),
          );
          StorageService.saveLearningProgress(_currentProgress!);
        }
      }
    });
  }

  void previousQuestion() {
    if (_currentQuestionBank == null) return;

    setState(() {
      if (_currentQuestionIndex > 0) {
        _currentQuestionIndex--;
        _isAnswered = currentQuestion!.isAnswered;

        // 保存顺序练习的进度
        if (_currentMode == QuizMode.sequential && _currentProgress != null) {
          _currentProgress = _currentProgress!.copyWith(
            currentQuestionIndex: _currentQuestionIndex,
            lastStudiedAt: DateTime.now(),
          );
          StorageService.saveLearningProgress(_currentProgress!);
        }
      }
    });
  }

  void jumpToQuestion(int index) {
    if (_currentQuestionBank == null) return;

    setState(() {
      if (index >= 0 && index < _currentQuestionBank!.questions.length) {
        _currentQuestionIndex = index;
        _isAnswered = currentQuestion!.isAnswered;

        // 保存顺序练习的进度
        if (_currentMode == QuizMode.sequential && _currentProgress != null) {
          _currentProgress = _currentProgress!.copyWith(
            currentQuestionIndex: _currentQuestionIndex,
            lastStudiedAt: DateTime.now(),
          );
          StorageService.saveLearningProgress(_currentProgress!);
        }
      }
    });
  }

  void resetQuiz() {
    if (_currentQuestionBank == null) return;

    setState(() {
      for (var question in _currentQuestionBank!.questions) {
        question.isAnswered = false;
        question.userAnswers = [];
      }
      _currentQuestionIndex = 0;
      _isAnswered = false;
      
      // 重置学习进度
      if (_currentProgress != null) {
        _currentProgress = _currentProgress!.copyWith(
          answeredQuestions: 0,
          correctQuestions: 0,
          wrongQuestionIds: [],
          lastStudiedAt: DateTime.now(),
        );
        StorageService.saveLearningProgress(_currentProgress!);
      }
    });
  }

  void setState(VoidCallback callback) {
    callback();
    notifyListeners();
  }
}
