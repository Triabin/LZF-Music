import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/slider_custom.dart';
import '../services/player_provider.dart';
import '../contants/app_contants.dart' show PlayMode;
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
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentSong?.title ?? "未知歌曲",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currentSong?.artist ?? "未知歌手",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 18,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  AnimatedTrackHeightSlider(
                                    value: _tempSliderValue >= 0
                                        ? _tempSliderValue
                                        : currentPosition,
                                    max: totalDuration,
                                    min: 0,
                                    activeColor: Colors.white,
                                    inactiveColor: Colors.white30,
                                    onChanged: (value) {
                                      setState(() {
                                        _tempSliderValue = value; // 暂存比例
                                      });
                                    },
                                    onChangeEnd: (value) {
                                      setState(() {
                                        _tempSliderValue =
                                            -1; // 复位，用实时 position 控制
                                      });
                                      playerProvider.seekTo(
                                        Duration(seconds: value.toInt()),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                        formatDuration(
                                          Duration(
                                            seconds: currentPosition.toInt(),
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.08,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "${currentSong?.bitrate != null ? (currentSong!.bitrate! / 1000).toStringAsFixed(0) : '未知'} kbps",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        formatDuration(
                                          Duration(
                                            seconds: totalDuration.toInt(),
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      IconButton(
                                        iconSize: 20,
                                        color: Colors.white70,
                                        icon: Icon(
                                          Icons.shuffle_rounded,
                                          color:
                                              playerProvider.playMode ==
                                                  PlayMode.shuffle
                                              ? Colors.white
                                              : null,
                                        ),
                                        onPressed: () {
                                          if (playerProvider.playMode ==
                                              PlayMode.shuffle) {
                                            playerProvider.setPlayMode(
                                              PlayMode.sequence,
                                            );
                                            return;
                                          }
                                          playerProvider.setPlayMode(
                                            PlayMode.shuffle,
                                          );
                                        },
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              iconSize: 48,
                                              color:
                                                  (playerProvider.hasPrevious ||
                                                      playerProvider.playMode ==
                                                          PlayMode.loop)
                                                  ? Colors.white
                                                  : Colors.white70,
                                              icon: const Icon(
                                                Icons.skip_previous_rounded,
                                              ),
                                              onPressed: () =>
                                                  playerProvider.previous(),
                                            ),
                                            const SizedBox(width: 16),
                                            IconButton(
                                              iconSize: 64,
                                              color: Colors.white,
                                              icon: Icon(
                                                isPlaying
                                                    ? Icons.pause_rounded
                                                    : Icons.play_arrow_rounded,
                                              ),
                                              onPressed: () =>
                                                  playerProvider.togglePlay(),
                                            ),
                                            const SizedBox(width: 16),
                                            IconButton(
                                              iconSize: 48,
                                              color:
                                                  (playerProvider.hasNext ||
                                                      playerProvider.playMode ==
                                                          PlayMode.loop)
                                                  ? Colors.white
                                                  : Colors.white70,
                                              icon: const Icon(
                                                Icons.skip_next_rounded,
                                              ),
                                              onPressed: () =>
                                                  playerProvider.next(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        iconSize: 20,
                                        color: Colors.white70,
                                        icon: Icon(
                                          playerProvider.playMode ==
                                                  PlayMode.singleLoop
                                              ? Icons.repeat_one_rounded
                                              : Icons.repeat_rounded,
                                          color:
                                              playerProvider.playMode ==
                                                      PlayMode.loop ||
                                                  playerProvider.playMode ==
                                                      PlayMode.singleLoop
                                              ? Colors.white
                                              : null,
                                        ),
                                        onPressed: () {
                                          if (playerProvider.playMode ==
                                              PlayMode.singleLoop) {
                                            playerProvider.setPlayMode(
                                              PlayMode.sequence,
                                            );
                                            return;
                                          }
                                          playerProvider.setPlayMode(
                                            playerProvider.playMode ==
                                                    PlayMode.loop
                                                ? PlayMode.singleLoop
                                                : PlayMode.loop,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.volume_down_rounded,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () {
                                          playerProvider.setVolume(
                                            playerProvider.volume - 0.1,
                                          );
                                        },
                                      ),
                                      Expanded(
                                        child: AnimatedTrackHeightSlider(
                                          trackHeight: 4,
                                          value: playerProvider.volume,
                                          max: 1.0,
                                          min: 0,
                                          activeColor: Colors.white,
                                          inactiveColor: Colors.white30,
                                          onChanged: (value) {
                                            playerProvider.setVolume(value);
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.volume_up_rounded,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () {
                                          playerProvider.setVolume(
                                            playerProvider.volume + 0.1,
                                          );
                                        },
                                      ),
                                    ],
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



class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class HoverIconButton extends StatefulWidget {
  final VoidCallback onPressed;

  const HoverIconButton({super.key, required this.onPressed});

  @override
  State<HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onPressed,
      borderRadius: BorderRadius.circular(4), // 圆角大小
      onHover: (v) {
        setState(() {
          _isHovered = !_isHovered;
        });
      },
      child: Icon(
        _isHovered ? Icons.keyboard_arrow_down_rounded : Icons.remove_rounded,
        color: Colors.white,
        size: 50,
      ),
    );
  }
}
