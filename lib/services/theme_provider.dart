import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/platform_utils.dart';
import 'package:flutter/services.dart';

class AppThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _seedColorKey = 'theme_seed_color';

  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = const Color(0xFF016B5B); // 默认主题色

  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final savedThemeIndex = _prefs?.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[savedThemeIndex];

    final savedColorValue = _prefs?.getInt(_seedColorKey);
    if (savedColorValue != null) {
      _seedColor = Color(savedColorValue);
    }

    notifyListeners();
  }

  // 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setInt(_themeKey, mode.index);
    notifyListeners();
  }


  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    await _prefs?.setInt(_seedColorKey, color.toARGB32());
    notifyListeners();
  }


  String getThemeName() {
    switch (_themeMode) {
      case ThemeMode.light:
        return '亮色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  IconData getThemeIcon() {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }


  ThemeData buildLightTheme() {
    return ThemeData(
      fontFamily: PlatformUtils.getFontFamily(),
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: PlatformUtils.isDesktopNotMac ? 56 : null,
      ),
    );
  }

  ThemeData buildDarkTheme() {
    return ThemeData(
      fontFamily: PlatformUtils.getFontFamily(),
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: PlatformUtils.isDesktop ? 56 : null,
      ),
    );
  }
}