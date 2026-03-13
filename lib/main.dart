import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'providers/quiz_provider.dart';
import 'utils/storage_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String _themeColor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThemeColor();
  }

  Future<void> _loadThemeColor() async {
    try {
      final prefs = await StorageService.getPrefs();
      _themeColor = prefs.getString('theme_color') ?? 'systemPurple';
    } catch (e) {
      _themeColor = 'systemPurple';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getThemeColor() {
    switch (_themeColor) {
      case 'systemBlue':
        return CupertinoColors.systemBlue;
      case 'systemPurple':
        return CupertinoColors.systemPurple;
      case 'systemRed':
        return CupertinoColors.systemRed;
      case 'systemGreen':
        return CupertinoColors.systemGreen;
      case 'systemOrange':
        return CupertinoColors.systemOrange;
      case 'systemPink':
        return CupertinoColors.systemPink;
      case 'systemIndigo':
        return CupertinoColors.systemIndigo;
      case 'systemTeal':
        return CupertinoColors.systemTeal;
      default:
        return CupertinoColors.systemPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoApp(
        home: Center(child: CupertinoActivityIndicator()),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => QuizProvider(),
      child: CupertinoApp(
        title: '刷题系统',
        theme: CupertinoThemeData(
          primaryColor: _getThemeColor(),
          brightness: Brightness.light,
          scaffoldBackgroundColor: CupertinoColors.systemBackground,
          textTheme: CupertinoTextThemeData(
            navTitleTextStyle: const TextStyle(
              inherit: true,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
            textStyle: const TextStyle(
              inherit: true,
              fontSize: 16,
              color: CupertinoColors.label,
            ),
            tabLabelTextStyle: const TextStyle(
              inherit: true,
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
            navLargeTitleTextStyle: const TextStyle(
              inherit: true,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

