import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../models/quiz_mode.dart';
import '../screens/quiz_screen.dart';
import '../utils/storage_service.dart';
import '../models/question_bank.dart';

class QuestionBankSelectionScreen extends StatefulWidget {
  final QuizMode mode;

  const QuestionBankSelectionScreen({super.key, required this.mode});

  @override
  State<QuestionBankSelectionScreen> createState() => _QuestionBankSelectionScreenState();
}

class _QuestionBankSelectionScreenState extends State<QuestionBankSelectionScreen> {
  List<QuestionBank> _questionBanks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestionBanks();
  }

  Future<void> _loadQuestionBanks() async {
    try {
      final banks = await StorageService.getAllQuestionBanks();
      setState(() {
        _questionBanks = banks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectQuestionBank(String bankId) async {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    await provider.loadQuestionBank(bankId, mode: widget.mode);
    
    // 导航到刷题页面
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => QuizScreen(mode: widget.mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_getTitle(), style: const TextStyle(inherit: true)),
        backgroundColor: CupertinoColors.systemBackground,
        leading: CupertinoNavigationBarBackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : _questionBanks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('暂无题库，请先导入题库', style: TextStyle(inherit: true, color: CupertinoColors.secondaryLabel)),
                          const SizedBox(height: 16),
                          CupertinoButton.filled(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('返回首页'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _questionBanks.length,
                      itemBuilder: (context, index) {
                        final bank = _questionBanks[index];
                        return CupertinoListTile(
                          title: Text(bank.name, style: const TextStyle(inherit: true, color: CupertinoColors.label)),
                          subtitle: Text('${bank.questions.length} 题', style: const TextStyle(inherit: true, color: CupertinoColors.secondaryLabel)),
                          trailing: const Icon(CupertinoIcons.chevron_right),
                          onTap: () {
                            _selectQuestionBank(bank.id);
                          },
                        );
                      },
                    ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.mode) {
      case QuizMode.sequential:
        return '选择顺序练习题库';
      case QuizMode.random:
        return '选择随机练习题库';
      case QuizMode.exam:
        return '选择考试题库';
      case QuizMode.wrongQuestions:
        return '选择错题练习题库';
    }
  }
}
