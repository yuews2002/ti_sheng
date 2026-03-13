import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/question_bank.dart';
import '../utils/storage_service.dart';
import '../utils/excel_parser.dart';

class QuestionBankManagementScreen extends StatefulWidget {
  const QuestionBankManagementScreen({super.key});

  @override
  State<QuestionBankManagementScreen> createState() => _QuestionBankManagementScreenState();

  // 添加页面过渡动画
  static Route<T> route<T>() {
    return CupertinoPageRoute<T>( 
      builder: (context) => const QuestionBankManagementScreen(),
    );
  }
}

class _QuestionBankManagementScreenState extends State<QuestionBankManagementScreen> {
  List<QuestionBank> _questionBanks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestionBanks();
  }

  Future<void> _loadQuestionBanks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _questionBanks = await StorageService.getAllQuestionBanks();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load question banks: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _importQuestionBank() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 打开文件选择器，选择Excel文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
        dialogTitle: '选择Excel题库文件',
      );

      if (result == null) {
        // 用户取消选择
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final file = result.files.single;
      final currentContext = context;

      // 解析Excel文件
      final questionBank = await ExcelParser.parseExcel(File(file.path!));

      await StorageService.saveQuestionBank(questionBank);

      if (mounted) {
        _loadQuestionBanks();
        showCupertinoDialog(
          context: currentContext,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('成功'),
            content: const Text('题库导入成功'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('错误'),
            content: Text('导入失败: $error'),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _deleteQuestionBank(String bankId) {
    final currentContext = context;
    showCupertinoDialog(
      context: currentContext,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个题库吗？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('删除'),
            onPressed: () {
              StorageService.deleteQuestionBank(bankId).then((_) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _loadQuestionBanks();
                    Navigator.pop(dialogContext);
                    showCupertinoDialog(
                      context: currentContext,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('成功'),
                        content: const Text('题库删除成功'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('确定'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  }
                });
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('题库管理', style: TextStyle(inherit: true)),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 导入题库按钮
              CupertinoButton.filled(
                onPressed: _importQuestionBank,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(CupertinoIcons.arrow_up_to_line, size: 20),
                    SizedBox(width: 8),
                    Text('导入题库', style: TextStyle( fontSize: 16)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              const SizedBox(height: 24),

              // 题库列表
              const Text(
                '已导入的题库',
                style: TextStyle(
                  
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(child: CupertinoActivityIndicator())
              else if (_questionBanks.isEmpty)
                const Center(
                  child: Text('暂无题库，请先导入', style: TextStyle( color: CupertinoColors.secondaryLabel)),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _questionBanks.length,
                    itemBuilder: (context, index) {
                      final bank = _questionBanks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(10),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  bank.name,
                                  style: const TextStyle(
                                    
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.label,
                                  ),
                                ),
                                CupertinoButton(
                                  onPressed: () => _deleteQuestionBank(bank.id),
                                  padding: EdgeInsets.zero,
                                  child: const Icon(CupertinoIcons.trash, color: CupertinoColors.systemRed, size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(bank.description, style: const TextStyle( color: CupertinoColors.secondaryLabel)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('题目数量: ${bank.totalQuestions}', style: const TextStyle( color: CupertinoColors.secondaryLabel)),
                                Text('创建时间: ${bank.createdAt.toString().substring(0, 10)}', style: const TextStyle( color: CupertinoColors.secondaryLabel)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
