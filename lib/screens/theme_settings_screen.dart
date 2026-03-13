import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../utils/storage_service.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  String _selectedColor = 'systemPurple';
  bool _isLoading = true;

  final Map<String, String> _colorOptions = {
    'systemBlue': '蓝色',
    'systemPurple': '紫色',
    'systemRed': '红色',
    'systemGreen': '绿色',
    'systemOrange': '橙色',
    'systemPink': '粉色',
    'systemIndigo': '靛蓝色',
    'systemTeal': '青绿色',
  };

  @override
  void initState() {
    super.initState();
    _loadSelectedColor();
  }

  Future<void> _loadSelectedColor() async {
    try {
      // 从存储中加载选中的颜色
      final prefs = await StorageService.getPrefs();
      final color = prefs.getString('theme_color') ?? 'systemPurple';
      setState(() {
        _selectedColor = color;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSelectedColor(String color) async {
    try {
      final prefs = await StorageService.getPrefs();
      await prefs.setString('theme_color', color);
      setState(() {
        _selectedColor = color;
      });
      // 显示保存成功提示
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('提示'),
          content: const Text('主题颜色已保存，重启应用后生效'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } catch (e) {
      // 显示保存失败提示
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('错误'),
          content: const Text('保存主题颜色失败'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('主题设置', style: TextStyle(inherit: true)),
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '选择主题颜色',
                      style: TextStyle(
                        inherit: true,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: _colorOptions.entries.map((entry) {
                        final colorName = entry.key;
                        final displayName = entry.value;
                        final isSelected = _selectedColor == colorName;

                        // 根据颜色名称获取对应的Cupertino颜色
                        Color color;
                        switch (colorName) {
                          case 'systemBlue':
                            color = CupertinoColors.systemBlue;
                            break;
                          case 'systemPurple':
                            color = CupertinoColors.systemPurple;
                            break;
                          case 'systemRed':
                            color = CupertinoColors.systemRed;
                            break;
                          case 'systemGreen':
                            color = CupertinoColors.systemGreen;
                            break;
                          case 'systemOrange':
                            color = CupertinoColors.systemOrange;
                            break;
                          case 'systemPink':
                            color = CupertinoColors.systemPink;
                            break;
                          case 'systemIndigo':
                            color = CupertinoColors.systemIndigo;
                            break;
                          case 'systemTeal':
                            color = CupertinoColors.systemTeal;
                            break;
                          default:
                            color = CupertinoColors.systemPurple;
                        }

                        return GestureDetector(
                          onTap: () {
                            _saveSelectedColor(colorName);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? color : CupertinoColors.separator,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    inherit: true,
                                    fontSize: 14,
                                    color: isSelected ? color : CupertinoColors.label,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '说明',
                      style: TextStyle(
                        inherit: true,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '选择的主题颜色将应用于应用的主色调，包括按钮、进度条等元素。修改后需要重启应用才能生效。',
                      style: TextStyle(
                        inherit: true,
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
