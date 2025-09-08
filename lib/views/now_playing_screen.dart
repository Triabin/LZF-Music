import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_provider.dart';
import 'package:lzf_music/widgets/lyrics_view.dart';
import 'package:lzf_music/widgets/music_control_panel.dart';

// 改进的NowPlayingScreen
class ImprovedNowPlayingScreen extends StatefulWidget {
  const ImprovedNowPlayingScreen({Key? key}) : super(key: key);

  @override
  State<ImprovedNowPlayingScreen> createState() =>
      _ImprovedNowPlayingScreenState();
}

class _ImprovedNowPlayingScreenState extends State<ImprovedNowPlayingScreen> {
  late ScrollController _scrollController;
  Timer? _timer;
  bool isHoveringLyrics = false;

  // 新增属性
  List<LyricLine> parsedLyrics = [];
  int lastCurrentIndex = -1;

  Map<int, double> lineHeights = {};
  double get placeholderHeight => 80;

  double _tempSliderValue = -1; // -1 表示没在拖动

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // 启动歌词更新定时器
    _startLyricsTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // 新增：启动定时器的方法
  void _startLyricsTimer() {
    _timer?.cancel();
    _timer = LyricsTimerManager.startLyricsTimer(
      () => mounted,
      () => Provider.of<PlayerProvider>(context, listen: false),
      parsedLyrics,
      () => lastCurrentIndex,
      (value) => lastCurrentIndex = value,
      () => setState(() {}),
      _scrollController,
      lineHeights,
      placeholderHeight,
      isHoveringLyrics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final currentSong = playerProvider.currentSong;
        final bool isPlaying = playerProvider.isPlaying;
        final double currentPosition = playerProvider.position.inSeconds
            .toDouble();
        final double totalDuration = playerProvider.duration.inSeconds
            .toDouble();

        // 处理歌词数据
        final lyricsResult = LyricsDataProcessor.processLyricsData(
          lyricsContent: currentSong?.lyrics,
          totalDuration: playerProvider.duration,
          currentPosition: playerProvider.position,
          parsedLyrics: parsedLyrics,
        );
        
        final int currentLine = lyricsResult.currentLine;
        final List<String> lyrics = lyricsResult.lyrics;

        // 你的原有UI代码保持完全不变
        return FocusScope(
          canRequestFocus: false,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (currentSong?.albumArtPath != null &&
                          File(currentSong!.albumArtPath!).existsSync())
                        Image.file(
                          File(currentSong.albumArtPath!),
                          fit: BoxFit.cover,
                        )
                      else
                        Container(color: Colors.black),
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: Colors.black87.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Row(
                    children: [
                      Flexible(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 50,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 380,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  HoverIconButton(
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child:
                                        currentSong?.albumArtPath != null &&
                                            File(
                                              currentSong!.albumArtPath!,
                                            ).existsSync()
                                        ? Image.file(
                                            File(currentSong.albumArtPath!),
                                            width: double.infinity,
                                            height: 300,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: double.infinity,
                                            height: 260,
                                            color: Colors.grey[800],
                                            child: const Icon(
                                              Icons.music_note_rounded,
                                              color: Colors.white,
                                              size: 48,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 24),
                                  SongInfoPanel(
                                    currentSong: currentSong,
                                    currentPosition: currentPosition,
                                    totalDuration: totalDuration,
                                    tempSliderValue: _tempSliderValue,
                                    onSliderChanged: (value) {
                                      setState(() {
                                        _tempSliderValue = value; // 暂存比例
                                      });
                                    },
                                    onSliderChangeEnd: (value) {
                                      setState(() {
                                        _tempSliderValue = -1; // 复位，用实时 position 控制
                                      });
                                      playerProvider.seekTo(
                                        Duration(seconds: value.toInt()),
                                      );
                                    },
                                    playerProvider: playerProvider,
                                  ),
                                  const SizedBox(height: 24),
                                  MusicControlButtons(
                                    playerProvider: playerProvider,
                                    isPlaying: isPlaying,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 6,
                        child: Center(
                          child: SizedBox(
                            height: 660,
                            width: 420,
                            child: ShaderMask(
                              shaderCallback: (rect) {
                                return const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black,
                                    Colors.black,
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.1, 0.9, 1.0],
                                ).createShader(rect);
                              },
                              blendMode: BlendMode.dstIn,
                              child: ScrollConfiguration(
                                behavior: NoGlowScrollBehavior(),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: 1 + lyrics.length + 2,
                                  itemBuilder: (context, index) {
                                    return LyricsListItemBuilder.buildItem(
                                      context: context,
                                      index: index,
                                      lyrics: lyrics,
                                      currentLine: currentLine,
                                      placeholderHeight: placeholderHeight,
                                      lineHeights: lineHeights,
                                      parsedLyrics: parsedLyrics,
                                      getLastCurrentIndex: () => lastCurrentIndex,
                                      setLastCurrentIndex: (value) => lastCurrentIndex = value,
                                      setState: () => setState(() {}),
                                      setHoveringState: (hover) => setState(() {
                                        isHoveringLyrics = hover;
                                      }),
                                      scrollController: _scrollController,
                                      isHoveringLyrics: isHoveringLyrics,
                                      playerProvider: playerProvider,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

// 测量Widget尺寸的工具类
typedef OnWidgetSizeChange = void Function(Size size);

class MeasureSize extends StatefulWidget {
  final Widget child;
  final OnWidgetSizeChange onChange;

  const MeasureSize({Key? key, required this.onChange, required this.child})
    : super(key: key);

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  Size? oldSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final contextSize = context.size;
      if (contextSize != null && oldSize != contextSize) {
        oldSize = contextSize;
        widget.onChange(contextSize);
      }
    });

    return widget.child;
  }
}