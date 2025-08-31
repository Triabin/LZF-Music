import 'package:flutter/material.dart';
import 'package:lzf_music/views/settings_page.dart';
import 'library_view.dart';
import 'playlists_view.dart';
import 'favorites_view.dart';
import 'recently_played_view.dart';
import 'storage_setting_page.dart';
import '../widgets/mini_player.dart';
import '../widgets/show_aware_page.dart';
import '../services/player_state_storage.dart';
import '../contants/app_contants.dart' show PlayerPage;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PlayerPage _currentPage = PlayerPage.library;
  bool isExtended = true;
  int _hoverIndex = -1;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final PlayerStateStorage playerState;

  final menuItems = const [
    {
      'icon': Icons.library_music_rounded,
      'iconSize': 22.0,
      'label': '库',
      'key': PlayerPage.library,
    },
    {
      'icon': Icons.favorite_rounded,
      'iconSize': 22.0,
      'label': '喜欢',
      'key': PlayerPage.favorite,
    },
    {
      'icon': Icons.playlist_play_rounded,
      'iconSize': 22.0,
      'label': '播放列表',
      'key': PlayerPage.playlist,
    },
    {
      'icon': Icons.history_rounded,
      'iconSize': 22.0,
      'label': '最近播放',
      'key': PlayerPage.recently,
    },
    {
      'icon': Icons.settings_rounded,
      'iconSize': 22.0,
      'label': '系统设置',
      'key': PlayerPage.settings,
    },
  ];

  // 每个页面对应一个 GlobalKey
  final pageKeys = [
    GlobalKey<LibraryViewState>(),
    GlobalKey<FavoritesViewState>(),
    GlobalKey<PlaylistsViewState>(),
    GlobalKey<RecentlyPlayedViewState>(),
    GlobalKey<SettingsPageState>(),
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadPlayerState();
    _pages = [
      LibraryView(key: pageKeys[0]),
      FavoritesView(key: pageKeys[1]),
      PlaylistsView(key: pageKeys[2]),
      RecentlyPlayedView(key: pageKeys[3]),
      SettingsPageWrapper(key: pageKeys[4], navigatorKey: _navigatorKey),
    ];
  }

  void _loadPlayerState() async {
    playerState = await PlayerStateStorage.getInstance();
    print(playerState.currentPage);
    setState(() {
      _currentPage = playerState.currentPage;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      (pageKeys[_currentPage.index].currentState as ShowAwarePage?)
          ?.onPageShow();
    });
  }

  void _onTabChanged(int newIndex) {
    if (newIndex == _currentPage.index) return;
    setState(() {
      _currentPage = PlayerPage.values[newIndex];
    });
    playerState.setCurrentPage(_currentPage);

    // 如果切换到非设置页面，需要重置设置页面的导航栈
    if (newIndex != 3) {
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = pageKeys[newIndex].currentState;
      if (state is ShowAwarePage) {
        state.onPageShow();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final brightness = theme.brightness;

    Color defaultTextColor = brightness == Brightness.dark
        ? Colors.grey[300]!
        : Colors.grey[800]!;

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isExtended ? 220 : 70,
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40.0, bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'LZF',
                        style: TextStyle(
                          height: 2,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder:
                            (Widget child, Animation<double> anim) {
                              return FadeTransition(
                                opacity: anim,
                                child: SizeTransition(
                                  axis: Axis.horizontal,
                                  sizeFactor: anim,
                                  child: child,
                                ),
                              );
                            },
                        child: isExtended
                            ? const Text(
                                ' Music',
                                style: TextStyle(
                                  height: 2,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            : const SizedBox(key: ValueKey('empty')),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final isSelected = index == _currentPage.index;
                      final isHovered = index == _hoverIndex;

                      Color bgColor;
                      Color textColor;

                      if (isSelected) {
                        bgColor = primary.withOpacity(0.2);
                        textColor = primary;
                      } else if (isHovered) {
                        bgColor = Colors.grey.withOpacity(0.2);
                        textColor = defaultTextColor;
                      } else {
                        bgColor = Colors.transparent;
                        textColor = defaultTextColor;
                      }

                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoverIndex = index),
                        onExit: (_) => setState(() => _hoverIndex = -1),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _onTabChanged(index),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item['icon'] as IconData,
                                  color: textColor,
                                  size: item['iconSize'] as double? ?? 20.0,
                                ),
                                Flexible(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: isExtended
                                        ? Padding(
                                            key: const ValueKey('text'),
                                            padding: const EdgeInsets.only(
                                              left: 12,
                                            ),
                                            child: Text(
                                              item['label'] as String,
                                              style: TextStyle(
                                                color: textColor,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )
                                        : const SizedBox(
                                            width: 0,
                                            key: ValueKey('empty'),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: IconButton(
                    icon: Icon(
                      isExtended
                          ? Icons.arrow_back_rounded
                          : Icons.menu_rounded,
                    ),
                    onPressed: () => setState(() => isExtended = !isExtended),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _currentPage.index,
                    children: _pages,
                  ),
                ),
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const MiniPlayer(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 设置页面包装器，包含独立的Navigator
class SettingsPageWrapper extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const SettingsPageWrapper({super.key, required this.navigatorKey});

  @override
  State<SettingsPageWrapper> createState() => SettingsPageWrapperState();
}

class SettingsPageWrapperState extends State<SettingsPageWrapper>
    implements ShowAwarePage {
  @override
  void onPageShow() {
    // 页面显示时的处理逻辑
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: widget.navigatorKey,
      onGenerateRoute: (RouteSettings settings) {
        print(settings.name);
        WidgetBuilder builder;
        switch (settings.name) {
          case '/settings':
            builder = (BuildContext context) => const SettingsPage();
            break;
          case '/storage-settings':
            builder = (BuildContext context) => const StorageSettingPage();
            break;
          default:
            builder = (BuildContext context) => const SettingsPage();
        }
        return MaterialPageRoute(builder: builder, settings: settings);
      },
    );
  }
}

// 在 SettingsPage 中使用导航的辅助函数
class NavigationHelper {
  static void navigateToStorageSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/storage-settings');
  }

  static void navigateBack(BuildContext context) {
    Navigator.of(context).pop();
  }
}
