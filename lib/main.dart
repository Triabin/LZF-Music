import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lzf_music/services/audio_player_service.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
// 桌面端窗口管理包 - 使用条件导入
import 'package:window_manager/window_manager.dart' if (dart.library.html) '';
import 'package:bitsdojo_window/bitsdojo_window.dart' if (dart.library.html) '';

import 'views/home_page.dart';
import 'services/player_provider.dart';
import 'database/database.dart';
import './services/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 确保 MediaKit 完全初始化
    MediaKit.ensureInitialized();

    final themeProvider = AppThemeProvider();
    await themeProvider.init();

    // 初始化数据库
    final musicDatabase = MusicDatabase();

    await AudioPlayerService.init();

    // 平台特定初始化
    if (_isDesktop()) {
      await _initializeDesktop();
    } else if (_isMobile()) {
      await _initializeMobile();
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider(create: (_) => PlayerProvider()),
          Provider<MusicDatabase>.value(value: musicDatabase),
        ],
        child: const MainApp(),
      ),
    );

    // Windows 平台额外设置
    if (Platform.isWindows) {
      doWhenWindowReady(() {
        final win = appWindow;
        win.minSize = const Size(1080, 720);
        win.size = const Size(1080, 720);
        win.alignment = Alignment.center;
        win.show();
      });
    }
  } catch (e) {
    debugPrint('应用初始化失败: $e');
  }
}

// 桌面端初始化
Future<void> _initializeDesktop() async {
  if (!_isDesktop()) return;

  try {
    // 确保窗口管理器初始化
    await windowManager.ensureInitialized();

    // 设置窗口选项，隐藏系统标题栏
    const WindowOptions windowOptions = WindowOptions(
      size: Size(1080, 720),
      minimumSize: Size(1080, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.show();
      await windowManager.focus();
    });
  } catch (e) {
    debugPrint('桌面端初始化失败: $e');
  }
}

// 移动端初始化
Future<void> _initializeMobile() async {
  if (!_isMobile()) return;

  try {
    // 移动端状态栏设置
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // 设置状态栏样式
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  } catch (e) {
    debugPrint('移动端初始化失败: $e');
  }
}

// 平台判断函数
bool _isDesktop() {
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

bool _isMobile() {
  return Platform.isAndroid || Platform.isIOS;
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.read<PlayerProvider>();
    return Consumer<AppThemeProvider>(
      builder: (context, themeProvider, child) {
        return FocusScope(
          autofocus: true,
          canRequestFocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.physicalKey == PhysicalKeyboardKey.space) {
                playerProvider.togglePlay();
                return KeyEventResult.handled;
              }
              if (event.physicalKey == PhysicalKeyboardKey.arrowLeft) {
                playerProvider.seekTo(
                  Duration(
                    seconds: max(playerProvider.position.inSeconds - 10, 0),
                  ),
                );
                return KeyEventResult.handled;
              }
              if (event.physicalKey == PhysicalKeyboardKey.arrowRight) {
                playerProvider.seekTo(
                  Duration(
                    seconds: min(
                      playerProvider.position.inSeconds + 10,
                      playerProvider.duration.inSeconds,
                    ),
                  ),
                );
                return KeyEventResult.handled;
              }
              if (event.physicalKey == PhysicalKeyboardKey.arrowUp) {
                playerProvider.previous();
                return KeyEventResult.handled;
              }
              if (event.physicalKey == PhysicalKeyboardKey.arrowDown) {
                playerProvider.next();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: MaterialApp(
            title: 'LZF Music',
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: themeProvider.themeMode,
            home: const HomePage(),
            builder: (context, child) {
              // 桌面端需要自定义标题栏
              if (_isDesktop()) {
                return Stack(
                  children: [
                    if (child != null) Positioned.fill(child: child),
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 30,
                      child: CustomTitleBar(),
                    ),
                  ],
                );
              }
              // 移动端直接返回内容
              return child ?? const SizedBox.shrink();
            },
          ),
        );
      },
    );
  }

  // 构建浅色主题
  ThemeData _buildLightTheme() {
    return ThemeData(
      fontFamily: _getFontFamily(),
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF016B5B),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // 桌面端需要考虑自定义标题栏的高度
        toolbarHeight: _isDesktop() ? 56 : null,
      ),
    );
  }

  // 构建深色主题
  ThemeData _buildDarkTheme() {
    return ThemeData(
      fontFamily: _getFontFamily(),
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF016B5B),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // 桌面端需要考虑自定义标题栏的高度
        toolbarHeight: _isDesktop() ? 56 : null,
      ),
    );
  }

  // 根据平台返回合适的字体
  String? _getFontFamily() {
    if (Platform.isWindows) {
      return 'Microsoft YaHei';
    } else if (Platform.isAndroid) {
      return 'Roboto';
    } else if (Platform.isIOS) {
      return 'SF Pro Display';
    } else if (Platform.isMacOS) {
      return 'SF Pro Display';
    } else if (Platform.isLinux) {
      return 'Ubuntu';
    }
    return null;
  }
}

// 自定义标题栏组件（仅桌面端使用）
class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    // 移动端不显示自定义标题栏
    if (_isMobile()) {
      return const SizedBox.shrink();
    }

    final brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;

    final buttonColors = WindowButtonColors(
      iconNormal: isDark ? Colors.white70 : Colors.black54,
      mouseOver: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
      mouseDown: isDark ? Colors.grey.shade800 : Colors.grey.shade400,
      iconMouseOver: isDark ? Colors.white : Colors.black,
      iconMouseDown: isDark ? Colors.white : Colors.black,
    );

    final closeButtonColors = WindowButtonColors(
      iconNormal: isDark ? Colors.white70 : Colors.black54,
      mouseOver: Colors.red.shade700,
      mouseDown: Colors.red.shade900,
      iconMouseOver: Colors.white,
      iconMouseDown: Colors.white,
    );

    return Container(
      color: Colors.transparent,
      child: WindowTitleBarBox(
        child: Row(
          children: [
            Expanded(child: MoveWindow()),
            Row(
              children: [
                MinimizeWindowButton(
                  colors: buttonColors,
                  onPressed: () => windowManager.minimize(),
                ),
                MaximizeWindowButton(
                  colors: buttonColors,
                  onPressed: () async {
                    bool maximized = await windowManager.isMaximized();
                    if (maximized) {
                      windowManager.restore();
                    } else {
                      windowManager.maximize();
                    }
                  },
                ),
                CloseWindowButton(
                  colors: closeButtonColors,
                  onPressed: () => windowManager.close(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
