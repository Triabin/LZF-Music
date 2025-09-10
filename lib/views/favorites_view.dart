import 'package:flutter/material.dart';
import 'dart:async';
import '../database/database.dart';
import '../services/music_import_service.dart';
import '../services/player_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/show_aware_page.dart';
import '../widgets/music_list_header.dart';
import '../widgets/music_list_view.dart';

class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => FavoritesViewState();
}

class FavoritesViewState extends State<FavoritesView> with ShowAwarePage {
  bool _isScrolling = false;
  Timer? _scrollTimer;
  final ScrollController _scrollController = ScrollController();
  late MusicDatabase database;
  late MusicImportService importService;
  List<Song> songs = [];
  String? orderField = null;
  String? orderDirection = null;
  String? searchKeyword = null;

  void onPageShow() {
    _loadSongs();
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

      // 重置之前的定时器
      _scrollTimer?.cancel();

      // 设置新的定时器
      _scrollTimer = Timer(const Duration(milliseconds: 150), () {
        if (mounted) {
          setState(() {
            _isScrolling = false;
          });
        }
      });
    });
  }

  // 在你的 StatefulWidget 中更新这个方法
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
        isFavorite: true,
      );

      setState(() {
        songs = loadedSongs;
      });

      print('加载了 ${loadedSongs.length} 首歌曲');
    } catch (e) {
      print('加载歌曲失败: $e');
      // 可以显示错误信息给用户
      setState(() {
        songs = [];
      });
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, child) {
        playerProvider.setDatabase(database);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0), // 左上右16，底部0
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
                  await importService.importFromDirectory();
                  await _loadSongs();
                },
                onImportFiles: () async {
                  await importService.importFiles(
                    onProgress: (processed, total) {
                      print('Processed $processed of $total files');
                    },
                  );
                  await _loadSongs();
                },
              ),
              const SizedBox(height: 24),
              MusicListHeader(
                songs: songs,
                orderField: orderField,
                orderDirection: orderDirection,
                allowReorder: true, // 收藏页面允许重排列
                onOrderChanged: (field, direction) {
                  setState(() {
                    orderField = field;
                    orderDirection = direction;
                  });
                  _loadSongs();
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: MusicListView(
                  songs: songs,
                  scrollController: _scrollController,
                  playerProvider: playerProvider,
                  database: database,
                  showCheckbox: false, // 收藏页面不显示复选框
                  checkedIds: const [],
                  onSongDeleted: _loadSongs,
                  onSongUpdated: () {
                    setState(() {
                      // 重新加载歌曲列表
                      _loadSongs();
                    });
                  },
                  onSongPlay: (song, playlist, index) {
                    playerProvider.playSong(song, playlist: playlist, index: index);
                  },
                  onCheckboxChanged: (songId, isChecked) {
                    // 收藏页面不使用复选框
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
    // 收起搜索框
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
          '喜欢',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        Text('共${widget.songs.length}首喜欢的音乐'),
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
                  borderRadius: BorderRadius.circular(16), // 圆角半径16，可调
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
      
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
