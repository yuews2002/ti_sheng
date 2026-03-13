import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question_bank.dart';
import '../models/learning_progress.dart';
import '../models/exam_result.dart';

class StorageService {
  static const String _questionBanksKey = 'question_banks';
  static const String _learningProgressKey = 'learning_progress';
  static const String _examResultsKey = 'exam_results';
  static const String _aiConfig = 'ai_config';

  static Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // 保存题库
  static Future<void> saveQuestionBank(QuestionBank questionBank) async {
    final prefs = await getPrefs();
    final banksMap = await _getQuestionBanksMap();
    banksMap[questionBank.id] = questionBank.toMap();
    await prefs.setString(_questionBanksKey, jsonEncode(banksMap));
  }

  static Future<String?> loadAiKey() async {
    final prefs = await getPrefs();
    return prefs.getString("$_aiConfig.key");
  }

  static Future<String?> loadAiModel() async {
    final prefs = await getPrefs();
    return prefs.getString("$_aiConfig.model");
  }

  static Future<void> saveAiConfig(String key, String model) async {
    final prefs = await getPrefs();
    await prefs.setString("$_aiConfig.key", key);
    await prefs.setString("$_aiConfig.model", model);
  }

  // 加载题库
  static Future<QuestionBank?> loadQuestionBank(String bankId) async {
    final banksMap = await _getQuestionBanksMap();
    if (banksMap.containsKey(bankId)) {
      return QuestionBank.fromMap(banksMap[bankId]);
    }
    return null;
  }

  // 获取所有题库
  static Future<List<QuestionBank>> getAllQuestionBanks() async {
    final banksMap = await _getQuestionBanksMap();
    return banksMap.values.map((map) => QuestionBank.fromMap(map)).toList();
  }

  // 删除题库
  static Future<void> deleteQuestionBank(String bankId) async {
    //clearAll();
    final prefs = await getPrefs();
    final banksMap = await _getQuestionBanksMap();
    banksMap.remove(bankId);
    await prefs.setString(_questionBanksKey, jsonEncode(banksMap));
  }

  // 保存学习进度
  static Future<void> saveLearningProgress(LearningProgress progress) async {
    final prefs = await getPrefs();
    final progressMap = await _getLearningProgressMap();
    progressMap[progress.questionBankId] = progress.toMap();
    await prefs.setString(_learningProgressKey, jsonEncode(progressMap));
  }

  // 加载学习进度
  static Future<LearningProgress?> loadLearningProgress(String bankId) async {
    final progressMap = await _getLearningProgressMap();
    if (progressMap.containsKey(bankId)) {
      return LearningProgress.fromMap(progressMap[bankId]);
    }
    return null;
  }

  // 内部方法：获取题库映射
  static Future<Map<String, dynamic>> _getQuestionBanksMap() async {
    final prefs = await getPrefs();
    final banksJson = prefs.getString(_questionBanksKey);
    if (banksJson == null) {
      return {};
    }
    return jsonDecode(banksJson) as Map<String, dynamic>;
  }

  // 内部方法：获取学习进度映射
  static Future<Map<String, dynamic>> _getLearningProgressMap() async {
    final prefs = await getPrefs();
    final progressJson = prefs.getString(_learningProgressKey);
    if (progressJson == null) {
      return {};
    }
    return jsonDecode(progressJson) as Map<String, dynamic>;
  }

  // 保存考试成绩
  static Future<void> saveExamResult(ExamResult result) async {
    final prefs = await getPrefs();
    final resultsMap = await _getExamResultsMap();
    resultsMap[result.id] = result.toMap();
    await prefs.setString(_examResultsKey, jsonEncode(resultsMap));
  }

  // 加载考试成绩
  static Future<ExamResult?> loadExamResult(String resultId) async {
    final resultsMap = await _getExamResultsMap();
    if (resultsMap.containsKey(resultId)) {
      return ExamResult.fromMap(resultsMap[resultId]);
    }
    return null;
  }

  // 加载所有考试成绩
  static Future<List<ExamResult>> loadAllExamResults() async {
    final resultsMap = await _getExamResultsMap();
    return resultsMap.values.map((map) => ExamResult.fromMap(map)).toList();
  }

  // 加载所有考试成绩（按题库ID）
  static Future<List<ExamResult>> loadExamResultsByBankId(String bankId) async {
    final resultsMap = await _getExamResultsMap();
    return resultsMap.values
        .map((map) => ExamResult.fromMap(map))
        .where((result) => result.questionBankId == bankId)
        .toList();
  }

  // 内部方法：获取考试成绩映射
  static Future<Map<String, dynamic>> _getExamResultsMap() async {
    final prefs = await getPrefs();
    final resultsJson = prefs.getString(_examResultsKey);
    if (resultsJson == null) {
      return {};
    }
    return jsonDecode(resultsJson) as Map<String, dynamic>;
  }

  // 清空所有数据（用于测试）
  static Future<void> clearAll() async {
    final prefs = await getPrefs();
    await prefs.remove(_questionBanksKey);
    await prefs.remove(_learningProgressKey);
    await prefs.remove(_examResultsKey);
  }
}
