import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lzf_music/utils/theme_utils.dart';
import 'package:provider/provider.dart';
import '../views/now_playing_screen.dart';
import '../services/player_provider.dart';
import './slider_custom.dart';
import '../contants/app_contants.dart' show PlayMode;

class MiniPlayer extends StatefulWidget {
  final double containerWidth;

  const MiniPlayer({
    super.key,
    this.containerWidth = double.infinity,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  double _tempSliderValue = -1; // -1 表示没在拖动

  @override
  Widget build(BuildContext context) {
    // 根据容器宽度决定显示哪些控件
    final showVolumeControl = widget.containerWidth > 765;
    final showProgressControl = widget.containerWidth > 600;
    double progressLength = (widget.containerWidth - 520).clamp(254, 312);
    if (!showProgressControl) {
      progressLength = widget.containerWidth - 348;
    }
    final activeColor = ThemeUtils.select(
      context,
      light: Colors.black87,
      dark: Colors.white,
    );
    final inactiveColor = ThemeUtils.select(
      context,
      light: Colors.black26,
      dark: Colors.white30,
    );

    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        final currentSong = playerProvider.currentSong;
        final position = playerProvider.position;
        final duration = playerProvider.duration;

        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 10.0,
          ),
          child: Row(
                children: [
                  const SizedBox(width: 4),
                  // 歌曲封面
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        if (currentSong == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImprovedNowPlayingScreen(),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          image: currentSong?.albumArtPath != null
                              ? DecorationImage(
                                  image: FileImage(
                                    File(currentSong!.albumArtPath!),
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: currentSong?.albumArtPath == null
                            ? const Icon(Icons.music_note_rounded, size: 24)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 歌曲信息
                  SizedBox(
                    width: progressLength, // 固定宽度
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentSong?.title ?? '未播放',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                currentSong?.artist ?? '选择歌曲开始播放',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showProgressControl)
                              SizedBox(
                                width: 92,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${_formatDuration(position)}/${_formatDuration(duration)}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (showProgressControl) ...[
                          SizedBox(height: 8),
                          Row(
                            children: [
                              // 进度条
                              Expanded(
                                child: AnimatedTrackHeightSlider(
                                  trackHeight: 4,
                                  value:
                                      (_tempSliderValue >= 0
                                              ? _tempSliderValue
                                              : (duration.inMilliseconds > 0
                                                    ? position.inMilliseconds /
                                                          duration
                                                              .inMilliseconds
                                                    : 0.0))
                                          .clamp(0.0, 1.0),
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: currentSong != null
                                      ? (value) {
                                          setState(() {
                                            _tempSliderValue = value; // 暂存比例
                                          });
                                        }
                                      : null,
                                  onChangeEnd: currentSong != null
                                      ? (value) async {
                                          final newPosition = Duration(
                                            milliseconds:
                                                (_tempSliderValue *
                                                        duration.inMilliseconds)
                                                    .round(),
                                          );
                                          await playerProvider.seekTo(
                                            newPosition,
                                          );
                                          setState(() {
                                            _tempSliderValue =
                                                -1; // 复位，用实时 position 控制
                                          });
                                        }
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),

                  Spacer(), // 右侧弹性空白
                  // 音量控制
                  if (showVolumeControl) ...[
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            playerProvider.volume <= 0
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            size: 20,
                          ),
                          onPressed: currentSong != null
                              ? () {
                                  if (playerProvider.volume > 0) {
                                    playerProvider.setVolume(0);
                                  } else {
                                    playerProvider.setVolume(1);
                                  }
                                }
                              : null,
                        ),
                        SizedBox(
                          width: 100,
                          child: AnimatedTrackHeightSlider(
                            trackHeight: 4,
                            value: playerProvider.volume,
                            min: 0.0,
                            max: 1.0,
                            onChanged: currentSong != null
                                ? (value) {
                                    playerProvider.setVolume(value);
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                  ],
                  IconButton(
                    iconSize: 20,
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: playerProvider.playMode == PlayMode.shuffle
                          ? activeColor
                          : inactiveColor,
                    ),
                    onPressed: () {
                      if (playerProvider.playMode == PlayMode.shuffle) {
                        playerProvider.setPlayMode(PlayMode.sequence);
                        return;
                      }
                      playerProvider.setPlayMode(PlayMode.shuffle);
                    },
                  ),
                  IconButton(
                    iconSize: 20,
                    icon: Icon(
                      playerProvider.playMode == PlayMode.singleLoop
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      color:
                          playerProvider.playMode == PlayMode.loop ||
                              playerProvider.playMode == PlayMode.singleLoop
                          ? activeColor
                          : inactiveColor,
                    ),
                    onPressed: () {
                      if (playerProvider.playMode == PlayMode.singleLoop) {
                        playerProvider.setPlayMode(PlayMode.sequence);
                        return;
                      }
                      playerProvider.setPlayMode(
                        playerProvider.playMode == PlayMode.loop
                            ? PlayMode.singleLoop
                            : PlayMode.loop,
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  // 控制按钮
                  Row(
                    children: [
                      // 上一首按钮
                      IconButton(
                        color: activeColor,
                        icon: Icon(Icons.skip_previous_rounded, size: 40),
                        onPressed:
                            (playerProvider.playMode == PlayMode.sequence &&
                                !playerProvider.hasPrevious)
                            ? null
                            : () async {
                                try {
                                  await playerProvider.previous();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('播放失败: $e')),
                                    );
                                  }
                                }
                              },
                      ),
                      // 播放/暂停按钮
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            color: activeColor,
                            icon: Icon(
                              playerProvider.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 40,
                            ),
                            onPressed: currentSong != null
                                ? () async {
                                    try {
                                      await playerProvider.togglePlay();
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('操作失败: $e')),
                                        );
                                      }
                                    }
                                  }
                                : null,
                          ),
                          // 加载指示器
                          if (playerProvider.isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      // 下一首按钮
                      IconButton(
                        color: activeColor,
                        icon: Icon(Icons.skip_next_rounded, size: 40),
                        onPressed:
                            (playerProvider.playMode == PlayMode.sequence &&
                                !playerProvider.hasNext)
                            ? null
                            : () async {
                                try {
                                  await playerProvider.next();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('播放失败: $e')),
                                    );
                                  }
                                }
                              },
                      ),
                    ],
                  ),
                ],
              ),
            );
      },
    );
  }
}

String _formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(d.inMinutes.remainder(60));
  final seconds = twoDigits(d.inSeconds.remainder(60));
  return "$minutes:$seconds";
}
