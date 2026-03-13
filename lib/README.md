# 刷题系统

一个基于Flutter 3.27.0的功能完整的刷题系统，支持类似驾考宝典的刷题逻辑。

## 功能特点

### 核心功能
- **多种刷题模式**：顺序练习、随机练习、模拟考试、错题练习
- **支持多种题型**：单选题、多选题
- **即时反馈**：答题后立即显示正确答案和解析
- **题库管理**：支持导入题库、查看题库列表
- **学习进度**：记录答题记录、学习进度和错题集

### 技术实现
- **数据模型**：清晰的数据结构，支持题目、选项、答案、解析等完整信息
- **状态管理**：使用Provider进行状态管理
- **数据持久化**：使用SharedPreferences存储数据
- **界面设计**：现代UI设计，流畅的动画效果，响应式布局

## 项目结构

```
lib/
├── models/           # 数据模型
│   ├── question.dart      # 题目和选项模型
│   ├── question_bank.dart # 题库模型
│   └── learning_progress.dart # 学习进度模型
├── providers/        # 状态管理
│   └── quiz_provider.dart # 刷题状态管理
├── screens/          # 页面
│   ├── main_screen.dart    # 主页面
│   ├── quiz_screen.dart    # 答题页面
│   └── question_bank_management_screen.dart # 题库管理页面
├── utils/            # 工具类
│   └── storage_service.dart # 存储服务
└── main.dart         # 应用入口
```

## 使用说明

1. **导入题库**：在主页面点击"题库管理"按钮，然后点击"导入题库"按钮导入题库
2. **选择刷题模式**：在主页面选择一种刷题模式（顺序练习、随机练习、模拟考试、错题练习）
3. **开始答题**：在答题页面选择答案，然后点击"提交答案"按钮
4. **查看解析**：提交答案后，系统会显示正确答案和解析
5. **切换题目**：点击"上一题"或"下一题"按钮切换题目
6. **完成答题**：答完所有题目后，点击"完成"按钮返回主页面

## 数据结构

### 题目（Question）
- id：题目ID
- content：题目内容
- type：题目类型（单选题、多选题）
- options：选项列表
- correctAnswers：正确答案列表
- explanation：解析
- isAnswered：是否已回答
- userAnswers：用户答案

### 选项（Option）
- id：选项ID
- content：选项内容

### 题库（QuestionBank）
- id：题库ID
- name：题库名称
- description：题库描述
- questions：题目列表
- createdAt：创建时间
- updatedAt：更新时间

### 学习进度（LearningProgress）
- id：进度ID
- questionBankId：题库ID
- totalQuestions：总题目数
- answeredQuestions：已回答题目数
- correctQuestions：正确题目数
- wrongQuestionIds：错题ID列表
- lastStudiedAt：最近学习时间
- createdAt：创建时间

## 未来扩展

- **题库导入**：支持从文件或网络导入题库
- **题库去重**：实现题库去重功能
- **统计分析**：添加学习统计和分析功能
- **多语言支持**：支持多语言界面
- **深色模式**：添加深色模式支持
