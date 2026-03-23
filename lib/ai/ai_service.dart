import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ti_sheng/utils/storage_service.dart';
import '../models/question.dart';

class AIService {
  // 阿里云百炼 API 配置（请替换为你自己的 API Key）
  static  String apiUrl = 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation';
  static String _apiKey = ''; // TODO: 替换为你的 API Key
  static String _model = '';
  static String _content = '';
  // 获取配置的 getter
  static String get apiKey => _apiKey;
  static String get model => _model;
  static String get content => _content;

  static Future<void> initializeConfig() async {
    final savedKey = await StorageService.loadAiKey();
    final savedModel = await StorageService.loadAiModel();
    final savedContent = await StorageService.loadAiContent();

    if (savedKey != null && savedKey.isNotEmpty) {
      _apiKey = savedKey;
    }

    if (savedModel != null && savedModel.isNotEmpty) {
      _model = savedModel;
    }

    if (savedContent != null && savedContent.isNotEmpty) {
      _content = savedContent;
    }
  }

  // 更新配置的方法
  static void updateConfig({required String apiKey, required String model, required String content}) {
    _apiKey = apiKey;
    _model = model;
    _content = content;
    StorageService.saveAiConfig(apiKey, model,content);
  }
  static Stream<String> analyzeQuestionStream(Question question) async* {
    final client = http.Client();
    http.StreamedResponse? streamedResponse;

    try {
      final prompt = _buildPrompt(question);

      final request = http.Request(
        'POST',
        Uri.parse(apiUrl),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'X-DashScope-SSE': 'enable', // 启用 SSE 流式输出
      });

      request.body = jsonEncode({
        'model': _model,
        'input': {
          'messages': [
            {
              'role': 'system',
              'content': _content,
            },
            {
              'role': 'user',
              'content': prompt
            }
          ]
        },
        'parameters': {
          'temperature': 0.7,
          'max_tokens': 1000
        }
      });

      streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200) {
        // 使用 LineSplitter 按行分割流式数据
        final stream = streamedResponse.stream.transform(utf8.decoder).transform(const LineSplitter());

        await for (final line in stream) {
          final trimmedLine = line.trim();

          // 跳过空行和注释
          if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) continue;

          // 处理 data: 开头的 SSE 数据
          if (trimmedLine.startsWith('data:')) {
            final data = trimmedLine.substring(5).trim();

            // 检查是否是结束标记
            if (data == '[DONE]') break;

            try {
              final jsonData = jsonDecode(data);

              // 提取文本内容（根据实际返回结构调整）
              String? text;

              if (jsonData['output'] != null) {
                // 尝试不同的字段路径
                text = jsonData['output']['text'] ??
                    jsonData['output']['content'] ??
                    jsonData['output']['message']?['content'];
              }

              if (text != null && text.isNotEmpty) {
                yield text;
              }
            } catch (e) {
              print('解析 SSE 数据失败：$e, 原始数据：$trimmedLine');
              continue;
            }
          }
        }
      } else {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('API 请求失败：${streamedResponse.statusCode} - $errorBody');
      }
    } catch (e) {//
      print('AI 分析错误：$e');
      yield 'AI 分析暂时不可用，请稍后重试。（错误：$e）';
    } finally {
      client.close();
    }
  }

  /// 分析题目并给出建议
  static Future<String> analyzeQuestion(Question question) async {
    try {
      final prompt = _buildPrompt(question);
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'qwen-plus',
          'input': {
            'messages': [
              {
                'role': 'system',
                'content': '你是一位专业的答题助手，擅长分析和解答题目。你的任务是根据用户提供的题目、选项、正确答案和解析，给出详细的解题思路、考点分析和记忆技巧。请用简洁清晰的语言回答。'
              },
              {
                'role': 'user',
                'content': prompt
              }
            ]
          },
          'parameters': {
            'temperature': 0.7,
            'max_tokens': 1000
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['output'] != null && data['output']['choices'] != null && data['output']['choices'].isNotEmpty) {
          return data['output']['choices'][0]['message']['content'];
        } else {
          throw Exception('AI 响应格式异常');
        }
      } else {
        throw Exception('API 请求失败：${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('AI 分析错误：$e');
      return 'AI 分析暂时不可用，请稍后重试。';
    }
  }

  /// 构建给 AI 的提示词
  static String _buildPrompt(Question question) {
    final typeText = question.type == QuestionType.singleChoice ? '单选题' : '多选题';
    
    StringBuffer prompt = StringBuffer();
    prompt.writeln('题目类型：$typeText');
    prompt.writeln('');
    prompt.writeln('题目内容：');
    prompt.writeln(question.content);
    prompt.writeln('');
    prompt.writeln('选项：');
    
    for (var option in question.options) {
      prompt.writeln('${option.id}. ${option.content}');
    }
    
    prompt.writeln('');
    prompt.writeln('正确答案：${question.correctAnswers.join(', ')}');
    prompt.writeln('');
    prompt.writeln('参考解析：${question.explanation}');
    prompt.writeln('');
    prompt.writeln('请根据以上信息，设进行回答');
    
    return prompt.toString();
  }

  /// 批量分析错题
  static Future<String> analyzeMistakes(List<Question> wrongQuestions) async {
    try {
      final prompt = _buildMistakesPrompt(wrongQuestions);
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'qwen-plus',
          'input': {
            'messages': [
              {
                'role': 'system',
                'content': '你是一位专业的学习顾问，擅长分析学生的错题并提供针对性的学习建议。请用鼓励性的语气，帮助学生理解错误原因并改进。'
              },
              {
                'role': 'user',
                'content': prompt
              }
            ]
          },
          'parameters': {
            'temperature': 0.7,
            'max_tokens': 1500
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['output'] != null && data['output']['choices'] != null && data['output']['choices'].isNotEmpty) {
          return data['output']['choices'][0]['message']['content'];
        } else {
          throw Exception('AI 响应格式异常');
        }
      } else {
        throw Exception('API 请求失败：${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('AI 分析错误：$e');
      return 'AI 分析暂时不可用，请稍后重试。';
    }
  }

  /// 构建错题分析的提示词
  static String _buildMistakesPrompt(List<Question> wrongQuestions) {
    StringBuffer prompt = StringBuffer();
    prompt.writeln('我完成了以下题目，但是都做错了。请帮我分析这些错题：');
    prompt.writeln('');
    
    for (int i = 0; i < wrongQuestions.length; i++) {
      final q = wrongQuestions[i];
      prompt.writeln('题目 ${i + 1}:');
      prompt.writeln(q.content);
      prompt.writeln('我的答案：${q.userAnswers.join(', ')}');
      prompt.writeln('正确答案：${q.correctAnswers.join(', ')}');
      prompt.writeln('解析：${q.explanation}');
      prompt.writeln('---');
    }
    
    prompt.writeln('');
    prompt.writeln('请为我提供：');
    prompt.writeln('1. 每道题的错误原因分析');
    prompt.writeln('2. 这些题目反映出的知识薄弱点');
    prompt.writeln('3. 针对性的复习建议');
    prompt.writeln('4. 类似题目的解题技巧总结');
    
    return prompt.toString();
  }
}
