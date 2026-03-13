import 'dart:io';
import 'package:excel/excel.dart';
import '../models/question_bank.dart';
import '../models/question.dart';

class ExcelParser {
  // 解析Excel文件并转换为题库
  static Future<QuestionBank> parseExcel(File file) async {
    try {
      // 读取Excel文件
      var bytes = await file.readAsBytes();
      var excel = Excel.decodeBytes(bytes);

      // 获取第一个工作表
      var sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) {
        throw Exception('Excel文件中没有工作表');
      }

      // 解析题库信息（假设第一行是题库信息）
      var headerRow = sheet.row(0);
      String bankName = file.path.split('/').last.split('.').first;
      String bankDescription = DateTime.now().toString();

      // 解析题目（从第二行开始）
      List<Question> questions = [];
      for (int i = 1; i < sheet.maxRows; i++) {
        List<Data?> row = sheet.row(i);
        if (row.isEmpty || _getValue(row[0]).isEmpty) {
          continue; // 跳过空行
        }

        Question? question = _parseQuestion(row);
        if (question != null) {
          questions.add(question);
        }
      }

      if (questions.isEmpty) {
        throw Exception('Excel文件中没有有效题目');
      }

      // 创建题库
      return QuestionBank(
        id: DateTime.now().toString(),
        name: bankName,
        description: bankDescription,
        questions: questions,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('解析Excel文件失败: $e');
    }
  }

  // 解析单行数据为题目
  static Question? _parseQuestion(List<Data?> row) {
    if (row.length < 6) {
      return null; // 数据不完整
    }

    String id = _getValue(row[0]);
    String content = _getValue(row[1]);
    String typeStr = _getValue(row[2]).toLowerCase();
    String optionsStr = _getValue(row[3]);
    String correctAnswersStr = _getValue(row[4]);
    String explanation = row.length > 5 ? _getValue(row[5]) : '';

    // 解析题目类型
    QuestionType type = typeStr == 'multiple' ? QuestionType.multipleChoice : QuestionType.singleChoice;

    // 解析选项
    List<Option> options = [];
    List<String> optionTexts = optionsStr.split('|');
    for (int i = 0; i < optionTexts.length; i++) {
      String optionText = optionTexts[i].trim();
      if (optionText.isNotEmpty) {
        options.add(Option(id: '${String.fromCharCode(65 + i)}', content: optionText));
      }
    }

    // 解析正确答案
    List<String> correctAnswers = correctAnswersStr.split(',').map((e) => e.trim()).toList();

    return Question(
      id: id,
      content: content,
      type: type,
      options: options,
      correctAnswers: correctAnswers,
      explanation: explanation,
    );
  }

  // 获取单元格值
  static String _getValue(dynamic cell) {
    if (cell == null) {
      return '';
    }
    if (cell is String) {
      return cell.trim();
    }
    if (cell is int || cell is double) {
      return cell.toString();
    }
    // 处理Excel单元格对象
    if (cell is Map) {
      if (cell.containsKey('v')) {
        return _getValue(cell['v']);
      }
    }
    if (cell is Data) {
      return _getValue(cell.value);
    }
    return cell.toString().trim();
  }
}