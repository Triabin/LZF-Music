import 'package:flutter/material.dart';
import 'dart:io';
import '../database/database.dart';
import '../services/player_provider.dart';
import '../widgets/compact_center_snack_bar.dart';
import '../widgets/song_action_menu.dart';

class MusicListView extends StatefulWidget {
  final List<Song> songs;
  final ScrollController? scrollController;
  final PlayerProvider playerProvider;
  final MusicDatabase database;
  final bool showCheckbox;
  final List<int> checkedIds;
  final VoidCallback? onSongDeleted;
  final VoidCallback? onSongUpdated;
  final Function(Song, List<Song>, int)? onSongPlay;
  final Function(int, bool)? onCheckboxChanged;

  const MusicListView({
    super.key,
    required this.songs,
    required this.playerProvider,
    required this.database,
    this.scrollController,
    this.showCheckbox = false,
    this.checkedIds = const [],
    this.onSongDeleted,
    this.onSongUpdated,
    this.onSongPlay,
    this.onCheckboxChanged,
  });

  @override
  State<MusicListView> createState() => _MusicListViewState();
}

class _MusicListViewState extends State<MusicListView> {
  int? _hoveredIndex;
  bool _isScrolling = false;
  
  // 为每个歌曲的收藏状态创建 ValueNotifier
  final Map<int, ValueNotifier<bool>> _favoriteNotifiers = {};

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final secondsStr = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$secondsStr";
  }

  void _handleSongPlay(int index) {
    if (widget.onSongPlay != null) {
      widget.onSongPlay!(widget.songs[index], widget.songs, index);
    } else {
      // 默认播放行为
      widget.playerProvider.playSong(
        widget.songs[index],
        playlist: widget.songs,
        index: index,
      );
    }
  }

  void _handleFavoriteToggle(int index) {
    final song = widget.songs[index];
    final newFavoriteState = !song.isFavorite;
    
    // 更新数据库
    widget.database.updateSong(
      song.copyWith(isFavorite: newFavoriteState),
    );
    
    // 更新本地列表中的歌曲状态
    widget.songs[index] = song.copyWith(isFavorite: newFavoriteState);
    
    // 只更新对应歌曲的收藏状态通知器
    _getFavoriteNotifier(song.id).value = newFavoriteState;
    
    CompactCenterSnackBar.show(
      context,
      newFavoriteState
          ? '已收藏 ${song.title} - ${song.artist ?? '未知艺术家'}'
          : '已取消收藏 ${song.title} - ${song.artist ?? '未知艺术家'}',
    );
    
    widget.onSongUpdated?.call();
  }
  
  // 获取或创建收藏状态通知器
  ValueNotifier<bool> _getFavoriteNotifier(int songId) {
    return _favoriteNotifiers.putIfAbsent(
      songId, 
      () => ValueNotifier<bool>(
        widget.songs.firstWhere((s) => s.id == songId).isFavorite
      )
    );
  }

  void _handleSongDelete(int index) {
    final song = widget.songs[index];
    widget.database.deleteSong(song.id);
    
    CompactCenterSnackBar.show(
      context,
      "已删除 ${song.title} - ${song.artist ?? '未知艺术家'}",
    );
    
    widget.onSongDeleted?.call();
  }
  
  @override
  void dispose() {
    // 清理 ValueNotifier 资源
    for (var notifier in _favoriteNotifiers.values) {
      notifier.dispose();
    }
    _favoriteNotifiers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          setState(() {
            _isScrolling = true;
            _hoveredIndex = null;
          });
        } else if (notification is ScrollEndNotification) {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) {
              setState(() {
                _isScrolling = false;
              });
            }
          });
        }
        return false;
      },
      child: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          // 占位空间 - 为标题栏预留空间
          const SliverToBoxAdapter(
            child: SizedBox(height: 100), // 标题栏高度
          ),
          // 列表内容 - 使用SliverFixedExtentList保持性能
          SliverFixedExtentList(
            itemExtent: 70, // 保持原有的性能优化
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = widget.songs[index];
                final isHovered = !_isScrolling && _hoveredIndex == index;
                final isSelected = widget.playerProvider.currentSong?.id == song.id;
                
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final containerWidth = constraints.maxWidth;
                    final showSampleAndBitrate = containerWidth > 900;
                    final showDuration = containerWidth > 700;
                    final showAlbum = containerWidth > 500;
                    
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : isHovered
                          ? Colors.grey.withOpacity(0.1)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          // 主要内容区域
                          Expanded(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              onEnter: (_) => setState(() => _hoveredIndex = index),
                              onExit: (_) => setState(() => _hoveredIndex = null),
                              child: GestureDetector(
                                onDoubleTap: () => _handleSongPlay(index),
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.transparent,
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      // 专辑封面
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: song.albumArtPath != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: Image.file(
                                                  File(song.albumArtPath!),
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.cover,
                                                  cacheWidth: 150,
                                                  cacheHeight: 150,
                                                ),
                                              )
                                            : const Icon(Icons.music_note_rounded),
                                      ),
                                      const SizedBox(width: 10),
                                      // 歌曲信息
                                      Expanded(
                                        child: Row(
                                          children: [
                                            // 歌曲名称
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                song.title,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: isSelected
                                                      ? Theme.of(context).colorScheme.primary
                                                      : Theme.of(context).colorScheme.onSurface,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // 艺术家
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                song.artist ?? '未知艺术家',
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Theme.of(context).colorScheme.primary
                                                      : Theme.of(context).colorScheme.onSurface,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // 专辑
                                            if (showAlbum)
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  song.album ?? '未知专辑',
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? Theme.of(context).colorScheme.primary
                                                        : Theme.of(context).colorScheme.onSurface,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            // 采样率
                                            if (showSampleAndBitrate)
                                              SizedBox(
                                                width: 70,
                                                child: Text(
                                                  song.sampleRate != null
                                                      ? '${(song.sampleRate! / 1000).toStringAsFixed(1)} kHz'
                                                      : '',
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Theme.of(context).colorScheme.primary
                                                      : Theme.of(context).colorScheme.onSurface,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // 比特率
                                            if (showSampleAndBitrate)
                                              SizedBox(
                                                width: 80,
                                                child: Text(
                                                  song.bitrate != null
                                                      ? '${(song.bitrate! / 1000).toStringAsFixed(0)} kbps'
                                                      : '',
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? Theme.of(context).colorScheme.primary
                                                        : Theme.of(context).colorScheme.onSurface,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            // 时长
                                            if (showDuration)
                                              SizedBox(
                                                width: 60,
                                                child: Text(
                                                  _formatDuration(song.duration ?? 0),
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? Theme.of(context).colorScheme.primary
                                                        : Theme.of(context).colorScheme.onSurface,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 收藏按钮
                          ValueListenableBuilder<bool>(
                            valueListenable: _getFavoriteNotifier(song.id),
                            builder: (context, isFavorite, child) {
                              return IconButton(
                                onPressed: () => _handleFavoriteToggle(index),
                                iconSize: 20,
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_outline_rounded,
                                  color: isFavorite ? Colors.red : null,
                                ),
                              );
                            },
                          ),
                          // 复选框或更多菜单
                          widget.showCheckbox
                              ? Checkbox(
                                  value: widget.checkedIds.contains(song.id),
                                  onChanged: (value) {
                                    widget.onCheckboxChanged?.call(song.id, value == true);
                                  },
                                )
                              : SongActionMenu(
                                  song: song,
                                  onDelete: () => _handleSongDelete(index),
                                  onFavoriteToggle: () => _handleFavoriteToggle(index),
                                ),
                        ],
                      ),
                    );
                  },
                );
              },
              childCount: widget.songs.length,
            ),
          ),
        ],
      ),
    );
  }
}