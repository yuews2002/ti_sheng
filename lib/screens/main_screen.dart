import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ti_sheng/ai/ai_service.dart';
import 'question_bank_management_screen.dart';
import 'question_bank_selection_screen.dart';
import 'theme_settings_screen.dart';
import '../models/quiz_mode.dart';
import '../utils/storage_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _totalQuestions = 0;
  int _answeredQuestions = 0;
  int _correctQuestions = 0;
  String _lastStudied = '暂无记录';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AIService.initializeConfig().then((_) {
      setState(() {
        _apiKeyController.text = AIService.apiKey;
        _modelController.text = AIService.model;
        _contentController.text = AIService.content;
      });
    });
    _loadLearningProgress();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    _contentController.dispose();
    super.dispose();
  }


  // 显示设置菜单
  void _showSettingsMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('设置'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showAIConfigDialog();
            },
            child: const Text('AI 配置'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ThemeSettingsScreen(),
                  settings: RouteSettings(),
                  transitionDuration: Duration.zero,
                ),
              );
            },
            child: const Text('主题设置'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          isDestructiveAction: true,
          child: const Text('取消'),
        ),
      ),
    );
  }

  // 显示 AI 配置对话框
  void _showAIConfigDialog() {
    // 重置输入框内容为当前配置
    _apiKeyController.text = AIService.apiKey;
    _modelController.text = AIService.model;
    _contentController.text = AIService.content;

    showCupertinoModalPopup(
      context: context,
      useRootNavigator: true,
      builder: (context) => GestureDetector(
        onTap: () {
          // 点击空白处收起键盘
          FocusScope.of(context).unfocus();
        },
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AI 配置',
                      style: TextStyle(
                        inherit: true,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: CupertinoColors.systemGrey,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              // 配置表单
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // API 密钥输入框
                      const Text(
                        'API 密钥',
                        style: TextStyle(
                          inherit: true,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CupertinoTextField(
                        controller: _apiKeyController,
                        placeholder: '请输入阿里云百炼 API 密钥',
                        padding: const EdgeInsets.all(12),
                        keyboardType: TextInputType.visiblePassword,
                        enableSuggestions: false,
                        autocorrect: false,
                        obscureText: true,
                        prefix: const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(
                            CupertinoIcons.padlock_solid,
                            color: CupertinoColors.systemGrey,
                            size: 20,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CupertinoColors.separator),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 模型选择
                      const Text(
                        '模型',
                        style: TextStyle(
                          inherit: true,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CupertinoTextField(
                        controller: _modelController,
                        placeholder: '请输入模型名称，如 qwen-plus',
                        padding: const EdgeInsets.all(12),
                        keyboardType: TextInputType.text,
                        prefix: const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(
                            CupertinoIcons.app_fill,
                            color: CupertinoColors.systemGrey,
                            size: 20,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CupertinoColors.separator),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '提示词',
                        style: TextStyle(
                          inherit: true,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CupertinoTextField(
                        controller: _contentController,
                        placeholder: '请输入 AI 回答提示词，例如:\n请分析这道题目的考点、解题思路和易错点',
                        padding: const EdgeInsets.all(12),
                        keyboardType: TextInputType.multiline,
                        minLines: 4,
                        maxLines: 8,
                        expands: false,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CupertinoColors.separator),
                        ),
                      ),
                      // 提示信息
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CupertinoColors.systemBlue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.info_circle,
                              color: CupertinoColors.systemBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: const Text(
                                'API 密钥和模型配置将保存到本地，用于 AI 分析功能。',
                                style: TextStyle(
                                  inherit: true,
                                  fontSize: 12,
                                  color: CupertinoColors.label,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 底部按钮
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: CupertinoColors.separator, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        color: CupertinoColors.systemGrey2,
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CupertinoButton.filled(
                        onPressed: () {
                          // 先收起键盘
                          FocusScope.of(context).unfocus();

                          // 保存配置
                          if (_apiKeyController.text.isEmpty || _modelController.text.isEmpty || _contentController.text.isEmpty) {
                            Navigator.pop(context);
                            showCupertinoDialog(
                              context: context,
                              builder: (ctx) => CupertinoAlertDialog(
                                title: const Text('提示'),
                                content: const Text('请填写完整的配置信息'),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('确定'),
                                    onPressed: () => Navigator.pop(ctx),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          // 更新 AIService 的配置
                          AIService.updateConfig(
                            apiKey: _apiKeyController.text,
                            model: _modelController.text,
                            content: _contentController.text,
                          );

                          Navigator.pop(context);

                          // 显示保存成功提示
                          showCupertinoDialog(
                            context: context,
                            builder: (ctx) => CupertinoAlertDialog(
                              title: const Text('保存成功'),
                              content: const Text('AI 配置已更新'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('确定'),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('保存'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // AI 配置相关
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Future<void> _loadLearningProgress() async {
    try {
      final banks = await StorageService.getAllQuestionBanks();
      int total = 0;
      int answered = 0;
      int correct = 0;
      DateTime? lastStudied;

      for (final bank in banks) {
        final progress = await StorageService.loadLearningProgress(bank.id);
        if (progress != null) {
          total += progress.totalQuestions;
          answered += progress.answeredQuestions;
          correct += progress.correctQuestions;
          if (lastStudied == null || progress.lastStudiedAt.isAfter(lastStudied)) {
            lastStudied = progress.lastStudiedAt;
          }
        } else {
          total += bank.questions.length;
        }
      }

      setState(() {
        _totalQuestions = total;
        _answeredQuestions = answered;
        _correctQuestions = correct;
        _lastStudied = lastStudied != null 
            ? '${lastStudied.year}-${lastStudied.month}-${lastStudied.day}'
            : '暂无记录';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('刷题系统'),
        backgroundColor: CupertinoColors.systemBackground,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showSettingsMenu,
          child: const Icon(
            CupertinoIcons.settings,
            color: CupertinoColors.systemGrey,
            size: 24,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 应用标题和介绍
              const Text(
                '欢迎使用刷题系统',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.systemPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '选择一种模式开始练习',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
                textAlign: TextAlign.center,
              ),
              // CupertinoButton(
              //   padding: const EdgeInsets.all(8),
              //   onPressed: _showAIConfigDialog,
              //   child: const Icon(
              //     CupertinoIcons.settings,
              //     color: CupertinoColors.systemGrey,
              //     size: 28,
              //   ),
              // ),

              // 刷题模式选择区域
              const Text(
                '刷题模式',
                style: TextStyle(
                  
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildModeCard(
                    context,
                    title: '顺序练习',
                    icon: CupertinoIcons.list_number,
                    onTap: () => _startQuiz(context, QuizMode.sequential),
                  ),
                  _buildModeCard(
                    context,
                    title: '随机练习',
                    icon: CupertinoIcons.shuffle,
                    onTap: () => _startQuiz(context, QuizMode.random),
                  ),
                  _buildModeCard(
                    context,
                    title: '模拟考试',
                    icon: CupertinoIcons.doc_text_fill,
                    onTap: () => _startQuiz(context, QuizMode.exam),
                  ),
                  _buildModeCard(
                    context,
                    title: '错题练习',
                    icon: CupertinoIcons.exclamationmark_circle_fill,
                    onTap: () => _startQuiz(context, QuizMode.wrongQuestions),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 题库管理入口
              CupertinoButton.filled(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const QuestionBankManagementScreen(),
                      settings: RouteSettings(),
                      transitionDuration: Duration.zero,
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(CupertinoIcons.arrow_up_to_line, size: 20),
                    SizedBox(width: 8),
                    Text('题库管理', style: TextStyle(inherit: true, fontSize: 16)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              const SizedBox(height: 16),

              // 学习进度概览
              const Text(
                '学习进度',
                style: TextStyle(
                  inherit: true,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CupertinoColors.separator),
                ),
                padding: const EdgeInsets.all(16.0),
                child: _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('已完成题目', style: TextStyle(inherit: true, color: CupertinoColors.label)),
                              Text('$_answeredQuestions/$_totalQuestions', style: const TextStyle(inherit: true, color: CupertinoColors.label)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('正确率', style: TextStyle(inherit: true, color: CupertinoColors.label)),
                              Text(
                                _answeredQuestions > 0
                                    ? '${((_correctQuestions / _answeredQuestions) * 100).toStringAsFixed(1)}%'
                                    : '0%',
                                style: const TextStyle(inherit: true, color: CupertinoColors.label),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('最近学习', style: TextStyle(inherit: true, color: CupertinoColors.label)),
                              Text(_lastStudied, style: const TextStyle(inherit: true, color: CupertinoColors.secondaryLabel)),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: CupertinoColors.systemPurple,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                inherit: true,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.label,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context, QuizMode mode) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => QuestionBankSelectionScreen(mode: mode),
        settings: RouteSettings(arguments: mode),
        transitionDuration: Duration.zero,
      ),
    );
  }
}
