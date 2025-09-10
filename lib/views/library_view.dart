import 'package:flutter/material.dart';

import 'dart:async';
import '../database/database.dart';
import '../services/music_import_service.dart';
import '../services/player_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/show_aware_page.dart';
import '../widgets/compact_center_snack_bar.dart';
import '../widgets/import_progress_dialog.dart';
import '../widgets/music_list_header.dart';
import '../widgets/music_list_view.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => LibraryViewState();
}

class LibraryViewState extends State<LibraryView> with ShowAwarePage {
  bool _isScrolling = false;
  Timer? _scrollTimer;
  final ScrollController _scrollController = ScrollController();
  late MusicDatabase database;
  late MusicImportService importService;
  List<Song> songs = [];
  String? orderField = null;
  String? orderDirection = null;
  String? searchKeyword = null;
  bool _showCheckbox = false;
  List<int> checkedIds = [];

  // 添加变量跟踪上一次的播放歌曲ID
  int? _lastCurrentSongId;
  // 添加标记来区分是否是用户在当前页面点击的
  bool _isUserClickedFromThisPage = false;

  @override
  void onPageShow() {
    _loadSongs().then((_) {
      // 页面首次显示且歌曲加载完成后，检查是否需要滚动到当前播放歌曲
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final playerProvider = Provider.of<PlayerProvider>(
          context,
          listen: false,
        );
        final currentSongId = playerProvider.currentSong?.id;
        if (currentSongId != null && mounted && _scrollController.hasClients) {
          _lastCurrentSongId = currentSongId;
          _scrollToCurrentSong(currentSongId);
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    database = Provider.of<MusicDatabase>(context, listen: false);
    importService = MusicImportService(database);

    _scrollController.addListener(() {
      if (!_isScrolling &&
          _scrollController.position.pixels !=
              _scrollController.position.minScrollExtent) {
        setState(() {
          _isScrolling = true;
        });
      }

      _scrollTimer?.cancel();
      _scrollTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted) {
          setState(() {
            _isScrolling = false;
          });
        }
      });
    });
  }

  // 添加滚动到指定歌曲的方法
  void _scrollToCurrentSong(int songId) {
    // 找到歌曲在列表中的索引
    final index = songs.indexWhere((song) => song.id == songId);
    if (index == -1) return; // 歌曲不在当前列表中

    // 计算滚动位置
    const itemHeight = 70.0; // itemExtent 的值
    const cardMargin = 0; // 卡片的垂直边距 (4 * 2)
    final targetPosition = index * (itemHeight + cardMargin);

    // 获取可视区域高度
    final viewportHeight = _scrollController.position.viewportDimension;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;

    // 计算理想的滚动位置（让目标歌曲出现在视口中央）
    final idealPosition =
        targetPosition - (viewportHeight / 2) + (itemHeight / 2);

    // 确保滚动位置在有效范围内
    final scrollPosition = idealPosition.clamp(0.0, maxScrollExtent);

    _scrollController.jumpTo(scrollPosition);
  }

  // 检查当前播放歌曲是否发生变化
  void _checkCurrentSongChange(PlayerProvider playerProvider) {
    final currentSongId = playerProvider.currentSong?.id;

    // 如果当前播放歌曲发生了变化
    if (currentSongId != _lastCurrentSongId && currentSongId != null) {
      _lastCurrentSongId = currentSongId;

      // 只有当不是用户在当前页面点击时才自动滚动
      if (!_isUserClickedFromThisPage) {
        // 延迟一点时间再滚动，确保UI已经更新
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollToCurrentSong(currentSongId);
          }
        });
      }

      // 重置标记
      _isUserClickedFromThisPage = false;
    }
  }

  Future<void> _loadSongs() async {
    try {
      print(
        "keyword $searchKeyword orderField $orderField orderDirection $orderDirection",
      );
      List<Song> loadedSongs;
      final keyword = searchKeyword;
      loadedSongs = await database.smartSearch(
        keyword?.trim(),
        orderField: orderField,
        orderDirection: orderDirection,
      );

      setState(() {
        songs = loadedSongs;
      });

      print('加载了 ${loadedSongs.length} 首歌曲');
    } catch (e) {
      print('加载歌曲失败: $e');
      setState(() {
        songs = [];
      });
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        playerProvider.setDatabase(database);

        // 在每次构建时检查当前播放歌曲是否发生变化
        _checkCurrentSongChange(playerProvider);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LibraryHeader(
                songs: songs,
                onSearch: (keyword) async {
                  searchKeyword = keyword;
                  await _loadSongs();
                },
                onImportDirectory: () async {
                  final updateProgress =
                      await ImportProgressDialog.showImportDialog(context);
                  updateProgress(isScanning: true);

                  bool hasProgress = false; // 标记是否有进度更新

                  String failedFiles = await importService.importFromDirectory(
                    onProgress: (processed, total) {
                      hasProgress = true; // 标记有进度更新
                      updateProgress(
                        processedFiles: processed,
                        totalFiles: total,
                        isScanning: false,
                      );
                    },
                  );

                  // 检查是否有进度更新，如果没有说明用户取消了选择
                  if (!hasProgress) {
                    // 用户取消了选择，直接关闭对话框
                    ImportProgressDialog.closeImportDialog(context);
                  } else {
                    // 有进度更新，显示完成状态
                    updateProgress(
                      isCompleted: true,
                      failedFileName: failedFiles,
                    );
                  }

                  await _loadSongs();
                },
                onImportFiles: () async {
                  final updateProgress =
                      await ImportProgressDialog.showImportDialog(context);
                  updateProgress(isScanning: true);

                  bool hasProgress = false; // 标记是否有进度更新

                  String failedFiles = await importService.importFiles(
                    onProgress: (processed, total) {
                      hasProgress = true; // 标记有进度更新
                      updateProgress(
                        processedFiles: processed,
                        totalFiles: total,
                        isScanning: false,
                      );
                    },
                  );

                  // 检查是否有进度更新，如果没有说明用户取消了选择
                  if (!hasProgress) {
                    // 用户取消了选择，直接关闭对话框
                    ImportProgressDialog.closeImportDialog(context);
                  } else {
                    // 有进度更新，显示完成状态
                    updateProgress(
                      isCompleted: true,
                      failedFileName: failedFiles,
                    );
                  }

                  await _loadSongs();
                },
              ),
              const SizedBox(height: 24),
              MusicListHeader(
                songs: songs,
                orderField: orderField,
                orderDirection: orderDirection,
                showCheckbox: _showCheckbox,
                checkedIds: checkedIds,
                allowReorder: true, // 库视图允许重排列
                onShowCheckboxToggle: () {
                  setState(() {
                    _showCheckbox = true;
                  });
                },
                onScrollToCurrent: () {
                  final playerProvider = Provider.of<PlayerProvider>(
                    context,
                    listen: false,
                  );
                  final currentSongId = playerProvider.currentSong?.id;
                  if (currentSongId != null) {
                    _scrollToCurrentSong(currentSongId);
                  } else {
                    CompactCenterSnackBar.show(context, '当前没有播放歌曲');
                  }
                },
                onOrderChanged: (field, direction) {
                  setState(() {
                    orderField = field;
                    orderDirection = direction;
                  });
                  _loadSongs();
                },
                onSelectAllChanged: (selectAll) {
                  setState(() {
                    if (selectAll) {
                      checkedIds
                        ..clear()
                        ..addAll(songs.map((s) => s.id));
                    } else {
                      checkedIds.clear();
                    }
                  });
                },
                onBatchAction: (action) async {
                  if (action == 'delete') {
                    bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('确认删除'),
                        content: const Text('确定要删除所选歌曲吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              '确定',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (checkedIds.isEmpty) {
                        CompactCenterSnackBar.show(
                          context,
                          '请勾选你要删除的歌曲',
                        );
                        return;
                      }
                      int len = checkedIds.length;
                      for (var id in checkedIds) {
                        database.deleteSong(id);
                      }
                      CompactCenterSnackBar.show(
                        context,
                        "已删除${len}首歌",
                      );
                      _loadSongs();
                      setState(() {
                        checkedIds.clear();
                        _showCheckbox = false;
                      });
                    }
                  } else if (action == 'hide') {
                    setState(() {
                      checkedIds.clear();
                      _showCheckbox = false;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: MusicListView(
                  songs: songs,
                  scrollController: _scrollController,
                  playerProvider: playerProvider,
                  database: database,
                  showCheckbox: _showCheckbox,
                  checkedIds: checkedIds,
                  onSongDeleted: _loadSongs,
                  onSongUpdated: () {
                    setState(() {
                      // 触发重建以更新收藏状态
                    });
                  },
                  onSongPlay: (song, playlist, index) {
                    // 标记这是用户在当前页面的点击操作
                    _isUserClickedFromThisPage = true;
                    playerProvider.playSong(song, playlist: playlist, index: index);
                  },
                  onCheckboxChanged: (songId, isChecked) {
                    setState(() {
                      if (isChecked) {
                        checkedIds.add(songId);
                      } else {
                        checkedIds.remove(songId);
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// LibraryHeader 类保持不变
class LibraryHeader extends StatefulWidget {
  final Future<void> Function(String? keyword) onSearch;
  final Future<void> Function() onImportDirectory;
  final Future<void> Function() onImportFiles;
  final List<Song> songs;

  const LibraryHeader({
    super.key,
    required this.onSearch,
    required this.onImportDirectory,
    required this.onImportFiles,
    required this.songs,
  });

  @override
  State<LibraryHeader> createState() => _LibraryHeaderState();
}

class _LibraryHeaderState extends State<LibraryHeader> {
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  void _onSubmitted(String? value) {
    widget.onSearch(value);
    setState(() {
      // _showSearch = false;
    });
    // _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '音乐库',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        Text('共${widget.songs.length}首音乐'),
        const Spacer(),
        if (_showSearch)
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '请输入搜索关键词',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onSubmitted: _onSubmitted,
            ),
          ),
        IconButton(
          icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
          onPressed: () {
            setState(() {
              if (_showSearch) {
                _searchController.clear();
              }
              if (_showSearch) {
                _showSearch = !_showSearch;
                _onSubmitted(null);
                return;
              }
              _showSearch = !_showSearch;
            });
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.folder_open_rounded),
          label: const Text('选择文件夹'),
          onPressed: () async {
            await widget.onImportDirectory();
          },
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          icon: const Icon(Icons.library_music_rounded),
          label: const Text('选择音乐文件'),
          onPressed: () async {
            await widget.onImportFiles();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('音乐文件导入完成')));
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
