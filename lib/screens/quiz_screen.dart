import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ti_sheng/ai/ai_service.dart';
import '../providers/quiz_provider.dart';
import '../models/question.dart';
import '../models/quiz_mode.dart';
import 'main_screen.dart';
import '../utils/storage_service.dart';


class QuizScreen extends StatefulWidget {
  final QuizMode mode;

  const QuizScreen({super.key, required this.mode});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _isAnalyzing = false;
  String _aiAnalysis='';
  StreamSubscription? _streamSubscription;
  // 缓存每个题目的 AI 解析，key 为题目 ID
  final Map<String, String> _aiAnalysisCache = {};


  @override
  void initState() {
    super.initState();
    
    // 加载题库数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuizData();
    });
  }

  Future<void> _loadQuizData() async {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    // 根据模式加载不同的题库
    //获取所有题库ID，随机一个
    await provider.loadQuestionBank('2026-03-12 08:22:46.766903', mode: widget.mode);
  }

  void _resetAIAnalysis(QuizProvider provider) {
    setState(() {
      _aiAnalysis = '';
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_getModeTitle(), style: const TextStyle(inherit: true)),
        backgroundColor: CupertinoColors.systemBackground,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      child: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (provider.currentQuestion == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('暂无题目，请先导入题库', style: TextStyle(inherit: true, color: CupertinoColors.secondaryLabel)),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('返回首页'),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 题目进度
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showQuestionJumpDialog(context, provider);
                        },
                        child: Text(
                          '题目 ${provider.currentQuestionIndex + 1}/${provider.currentQuestionBank?.questions.length}',
                          style: const TextStyle(inherit: true, fontSize: 16, color: CupertinoColors.systemBlue),
                        ),
                      ),
                      Text(
                        '得分: ${provider.currentProgress?.correctQuestions ?? 0}',
                        style: const TextStyle(inherit: true, fontSize: 16, color: CupertinoColors.label),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 进度条
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: CupertinoColors.systemGrey5,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (provider.currentQuestionIndex + 1) / (provider.currentQuestionBank?.questions.length ?? 1),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: CupertinoColors.systemPurple,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 题目内容
                  Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CupertinoColors.separator),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withOpacity(0.05),
                          spreadRadius: 0,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      provider.currentQuestion!.content,
                      style: const TextStyle(inherit: true, fontSize: 18, color: CupertinoColors.label),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 选项区域
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.currentQuestion!.options.length,
                      itemBuilder: (context, index) {
                        final option = provider.currentQuestion!.options[index];
                        final isSelected = provider.currentQuestion!.userAnswers.contains(option.id);
                        final isCorrect = provider.currentQuestion!.correctAnswers.contains(option.id);
                        final isAnswered = provider.currentQuestion!.isAnswered;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isAnswered
                                  ? isSelected
                                  ? isCorrect
                                  ? CupertinoColors.systemGreen.withOpacity(0.1)
                                  : CupertinoColors.systemRed.withOpacity(0.1)
                                  : isCorrect
                                  ? CupertinoColors.systemGreen.withOpacity(0.1)
                                  : CupertinoColors.systemBackground
                                  : CupertinoColors.systemBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAnswered
                                    ? isSelected
                                    ? isCorrect
                                    ? CupertinoColors.systemGreen
                                    : CupertinoColors.systemRed
                                    : isCorrect
                                    ? CupertinoColors.systemGreen
                                    : CupertinoColors.separator
                                    : CupertinoColors.separator,
                              ),
                            ),
                            child: CupertinoListTile(
                              title: Text(option.content, style: const TextStyle(inherit: true, color: CupertinoColors.label)),
                              leading: isAnswered
                                  ? Icon(
                                isSelected
                                    ? isCorrect
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.xmark_circle_fill
                                    : isCorrect
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : null,
                                color: isSelected
                                    ? isCorrect
                                    ? CupertinoColors.systemGreen
                                    : CupertinoColors.systemRed
                                    : isCorrect
                                    ? CupertinoColors.systemGreen
                                    : null,
                              )
                                  : provider.currentQuestion!.type == QuestionType.singleChoice
                                  ? CupertinoRadio<String>(
                                value: option.id,
                                groupValue: provider.currentQuestion!.userAnswers.isNotEmpty
                                    ? provider.currentQuestion!.userAnswers.first
                                    : null,
                                onChanged: provider.isAnswered
                                    ? null
                                    : (value) {
                                  if (value != null) {
                                    provider.selectAnswer(value);
                                  }
                                },
                              )
                                  : null,
                              trailing: provider.currentQuestion!.type == QuestionType.multipleChoice
                                  ? CupertinoCheckbox(
                                value: isSelected,
                                onChanged: provider.isAnswered
                                    ? null
                                    : (value) {
                                  if (value != null) {
                                    provider.selectAnswer(option.id);
                                  }
                                },
                              )
                                  : null,
                              onTap: provider.isAnswered
                                  ? null
                                  : () {
                                provider.selectAnswer(option.id);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // const SizedBox(height: 16),

                  // 解析区域（答题后显示）
                  if (provider.isAnswered)
                    Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CupertinoColors.systemBlue.withOpacity(0.2)),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '解析:',
                                style: TextStyle(
                                  inherit: true,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.label,
                                ),
                              ),
                              Row(
                                children: [
                                  if (_isAnalyzing)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4.0),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CupertinoActivityIndicator(radius: 4),
                                      ),
                                    ),
                                  CupertinoButton(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                    onPressed: _isAnalyzing ? null : () => _analyzeWithAI(provider),
                                    child: Text(
                                      _aiAnalysis.isEmpty ? 'AI 分析' : '重新分析',
                                      style: const TextStyle(
                                        inherit: true,
                                        fontSize: 14,
                                        color: CupertinoColors.systemBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // const SizedBox(height: 8),
                          Text(provider.currentQuestion!.explanation, style: const TextStyle(inherit: true, color: CupertinoColors.label)),

                          // AI 分析结果（流式显示）
                          if (_aiAnalysis.isNotEmpty) ...[
                            // const SizedBox(height: 12),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemBackground.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: CupertinoColors.systemOrange.withOpacity(0.3)),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: SingleChildScrollView(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      CupertinoIcons.sparkles,
                                      size: 20,
                                      color: CupertinoColors.systemOrange,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _aiAnalysis,
                                        style: const TextStyle(
                                          inherit: true,
                                          fontSize: 14,
                                          color: CupertinoColors.label,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          
                          // 错题练习模式下显示"学会了"按钮
                          if (widget.mode == QuizMode.wrongQuestions)
                            CupertinoButton.filled(
                              onPressed: () {
                                // 从错题本中移除该题目
                                if (provider.currentProgress != null) {
                                  final wrongQuestionIds = List<String>.from(provider.currentProgress!.wrongQuestionIds);
                                  if (wrongQuestionIds.contains(provider.currentQuestion!.id)) {
                                    wrongQuestionIds.remove(provider.currentQuestion!.id);
                                    final updatedProgress = provider.currentProgress!.copyWith(
                                      wrongQuestionIds: wrongQuestionIds,
                                      lastStudiedAt: DateTime.now(),
                                    );
                                    StorageService.saveLearningProgress(updatedProgress);
                                    // 显示提示
                                    showCupertinoDialog(
                                      context: context,
                                      builder: (context) => CupertinoAlertDialog(
                                        title: const Text('提示'),
                                        content: const Text('该题目已从错题本中移除'),
                                        actions: [
                                          CupertinoDialogAction(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              // 跳转到下一题或返回
                                              if (provider.currentQuestionIndex < (provider.currentQuestionBank?.questions.length ?? 1) - 1) {
                                                provider.nextQuestion();
                                              } else {
                                                Navigator.pop(context);
                                              }
                                            },
                                            child: const Text('确定'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text('我已经学会了这题'),
                            ),
                        ],
                      ),
                    ),
// ... existing code ...

                  const SizedBox(height: 16),

                  // 导航按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: CupertinoButton(
                            onPressed: provider.currentQuestionIndex > 0
                                ? () {
                              _resetAIAnalysis(provider);
                              provider.previousQuestion();
                            }
                                : null,
                            color: CupertinoColors.systemGrey2,
                            child: const Text('上一题'),
                          ),
                        ),
                      ),
                      if (!provider.isAnswered)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: CupertinoButton.filled(
                              onPressed: provider.currentQuestion!.userAnswers.isNotEmpty
                                  ? provider.submitAnswer
                                  : null,
                              child: const Text('提交答案'),
                            ),
                          ),
                        ),
                      if (provider.isAnswered)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: CupertinoButton.filled(
                              onPressed: provider.currentQuestionIndex < (provider.currentQuestionBank?.questions.length ?? 1) - 1
                                  ? () {
                                _resetAIAnalysis(provider);
                                provider.nextQuestion();
                              }
                                  : () {
                                // 完成答题，返回首页
                                Navigator.pop(context);
                              },
                              child: provider.currentQuestionIndex < (provider.currentQuestionBank?.questions.length ?? 1) - 1
                                  ? const Text('下一题')
                                  : const Text('完成'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getModeTitle() {
    switch (widget.mode) {
      case QuizMode.sequential:
        return '顺序练习';
      case QuizMode.random:
        return '随机练习';
      case QuizMode.exam:
        return '模拟考试';
      case QuizMode.wrongQuestions:
        return '错题练习';
    }
  }

  void _showQuestionJumpDialog(BuildContext context, QuizProvider provider) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 400,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '跳转到题目',
                style: TextStyle(
                  inherit: true,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 5,
                padding: const EdgeInsets.all(16.0),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: List.generate(
                  provider.currentQuestionBank?.questions.length ?? 0,
                  (index) {
                    final question = provider.currentQuestionBank!.questions[index];
                    final isCurrent = index == provider.currentQuestionIndex;
                    final isAnswered = question.isAnswered;
                    final isCorrect = question.isCorrect;
                    
                    Color backgroundColor;
                    if (isCurrent) {
                      backgroundColor = CupertinoColors.systemBlue.withOpacity(0.2);
                    } else if (isAnswered) {
                      backgroundColor = isCorrect
                          ? CupertinoColors.systemGreen.withOpacity(0.2)
                          : CupertinoColors.systemRed.withOpacity(0.2);
                    } else {
                      backgroundColor = CupertinoColors.systemGrey.withOpacity(0.2);
                    }
                    
                    Color textColor;
                    if (isCurrent) {
                      textColor = CupertinoColors.systemBlue;
                    } else if (isAnswered) {
                      textColor = isCorrect
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemRed;
                    } else {
                      textColor = CupertinoColors.systemGrey;
                    }
                    
                    return GestureDetector(
                      onTap: () {
                        provider.jumpToQuestion(index);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? CupertinoColors.systemBlue
                                : isAnswered
                                    ? isCorrect
                                        ? CupertinoColors.systemGreen
                                        : CupertinoColors.systemRed
                                    : CupertinoColors.systemGrey,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              inherit: true,
                              fontSize: 16,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            CupertinoButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeWithAI(QuizProvider provider) async {
    if (provider.currentQuestion == null) return;
    if (provider.currentQuestion == null) return;

    final questionId = provider.currentQuestion!.id;

    // 如果已经有缓存，直接使用缓存
    if (_aiAnalysisCache.containsKey(questionId)) {
      setState(() {
        _aiAnalysis = _aiAnalysisCache[questionId]!;
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _aiAnalysis = '';
    });

    try {
      // 取消之前的订阅
      _streamSubscription?.cancel();

      // 开始流式监听
      _streamSubscription = AIService.analyzeQuestionStream(provider.currentQuestion!).listen(
            (chunk) {
          // 直接替换而不是追加，避免重复
          setState(() {
            _aiAnalysis = chunk;
          });
        },
        onDone: () {
          if (_aiAnalysis.isNotEmpty) {
            _aiAnalysisCache[questionId] = _aiAnalysis;
          }
          setState(() {
            _isAnalyzing = false;
          });
        },
        onError: (error) {
          setState(() {
            _aiAnalysis = 'AI 分析失败：$error';
            _isAnalyzing = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _aiAnalysis = 'AI 分析失败：$e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

