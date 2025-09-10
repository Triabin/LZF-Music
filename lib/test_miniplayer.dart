import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'widgets/mini_player.dart';
import 'services/player_provider.dart';
import 'services/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 MediaKit
  MediaKit.ensureInitialized();
  
  final themeProvider = AppThemeProvider();
  await themeProvider.init();
  
  runApp(TestMiniPlayerApp(themeProvider: themeProvider));
}

class TestMiniPlayerApp extends StatelessWidget {
  final AppThemeProvider themeProvider;
  
  const TestMiniPlayerApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
      ],
      child: Consumer<AppThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MiniPlayer Test',
            theme: themeProvider.buildLightTheme().copyWith(
              scaffoldBackgroundColor: Colors.white,
            ),
            darkTheme: themeProvider.buildDarkTheme().copyWith(
              scaffoldBackgroundColor: Colors.white,
            ),
            themeMode: ThemeMode.light, // 强制使用浅色主题
            home: const TestMiniPlayerScreen(),
          );
        },
      ),
    );
  }
}

class TestMiniPlayerScreen extends StatefulWidget {
  const TestMiniPlayerScreen({super.key});

  @override
  State<TestMiniPlayerScreen> createState() => _TestMiniPlayerScreenState();
}

class _TestMiniPlayerScreenState extends State<TestMiniPlayerScreen> {
  double _containerWidth = 900;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiniPlayer Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.light_mode),
            onPressed: () {
              final themeProvider = Provider.of<AppThemeProvider>(context, listen: false);
              themeProvider.setThemeMode(
                themeProvider.themeMode == ThemeMode.light 
                  ? ThemeMode.dark 
                  : ThemeMode.light
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 宽度控制滑块
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Container Width: ${_containerWidth.toInt()}px'),
                Slider(
                  value: _containerWidth,
                  min: 400,
                  max: 1200,
                  divisions: 80,
                  onChanged: (value) {
                    setState(() {
                      _containerWidth = value;
                    });
                  },
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // MiniPlayer 测试区域
          Container(
            width: _containerWidth,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: MiniPlayer(containerWidth: _containerWidth),
          ),
          
          const Spacer(),
          
          // 信息显示
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer<PlayerProvider>(
              builder: (context, playerProvider, child) {
                return Column(
                  children: [
                    Text('Current Song: ${playerProvider.currentSong?.title ?? "None"}'),
                    Text('Is Playing: ${playerProvider.isPlaying}'),
                    Text('Volume: ${(playerProvider.volume * 100).toInt()}%'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
