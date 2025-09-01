import 'package:flutter/material.dart';
import '../contants/app_contants.dart';
import '../views/library_view.dart';
import '../views/playlists_view.dart';
import '../views/favorites_view.dart';
import '../views/recently_played_view.dart';
import '../router/nested_navigator_wrapper.dart';
import '../router/settings_routes.dart';
import '../storage/player_state_storage.dart';
import '../widgets/show_aware_page.dart';

/// 单个菜单项
class MenuItem {
  final IconData icon;
  final double iconSize;
  final String label;
  final PlayerPage key;
  final GlobalKey pageKey;
  final Widget Function(GlobalKey key) builder;

  const MenuItem({
    required this.icon,
    required this.iconSize,
    required this.label,
    required this.key,
    required this.pageKey,
    required this.builder,
  });

  Widget buildPage() => builder(pageKey);
}

/// 菜单和页面统一管理器
class MenuManager {
  MenuManager._();

  static final MenuManager _instance = MenuManager._();

  factory MenuManager() => _instance;

  /// 当前页面
  final ValueNotifier<PlayerPage> currentPage = ValueNotifier(
    PlayerPage.library,
  );

  /// 菜单是否展开
  final ValueNotifier<bool> isExtended = ValueNotifier(true);

  /// 当前 hover 的菜单项
  final ValueNotifier<int> hoverIndex = ValueNotifier(-1);

  /// 页面实例缓存
  late final List<Widget> pages;

  /// 导航器 Key（供需要嵌套导航的页面使用）
  late final GlobalKey<NavigatorState> navigatorKey;

  /// 所有菜单项
  late final List<MenuItem> items;

  /// 初始化（必须调用一次）
  Future<void> init({required GlobalKey<NavigatorState> navigatorKey}) async {
    this.navigatorKey = navigatorKey;

    items = [
      MenuItem(
        icon: Icons.library_music_rounded,
        iconSize: 22.0,
        label: '库',
        key: PlayerPage.library,
        pageKey: GlobalKey<LibraryViewState>(),
        builder: (key) => LibraryView(key: key),
      ),
      MenuItem(
        icon: Icons.favorite_rounded,
        iconSize: 22.0,
        label: '喜欢',
        key: PlayerPage.favorite,
        pageKey: GlobalKey<FavoritesViewState>(),
        builder: (key) => FavoritesView(key: key),
      ),
      MenuItem(
        icon: Icons.playlist_play_rounded,
        iconSize: 22.0,
        label: '播放列表',
        key: PlayerPage.playlist,
        pageKey: GlobalKey<PlaylistsViewState>(),
        builder: (key) => PlaylistsView(key: key),
      ),
      MenuItem(
        icon: Icons.history_rounded,
        iconSize: 22.0,
        label: '最近播放',
        key: PlayerPage.recently,
        pageKey: GlobalKey<RecentlyPlayedViewState>(),
        builder: (key) => RecentlyPlayedView(key: key),
      ),
      MenuItem(
        icon: Icons.settings_rounded,
        iconSize: 22.0,
        label: '系统设置',
        key: PlayerPage.settings,
        pageKey: GlobalKey<NestedNavigatorWrapperState>(),
        builder: (key) => NestedNavigatorWrapper(
          key: key,
          navigatorKey: navigatorKey,
          initialRoute: '/settings',
          routes: settingsRoutes,
        ),
      ),
    ];

    // 构建页面缓存
    pages = items.map((item) => item.buildPage()).toList();

    // 恢复上次状态
    final playerState = await PlayerStateStorage.getInstance();
    currentPage.value = playerState.currentPage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state =
          items[currentPage.value.index].pageKey.currentState as ShowAwarePage?;
      state?.onPageShow();
    });
  }

  /// 切换页面
  void setPage(PlayerPage page) {
    if (page == currentPage.value) return;
    final oldPage = currentPage.value;
    currentPage.value = page;

    // 保存状态
    PlayerStateStorage.getInstance().then((s) => s.setCurrentPage(page));

    // 离开设置页面时重置导航栈
    final oldItem = items[oldPage.index];
    if (oldItem.pageKey.currentState is NestedNavigatorWrapperState) {
      (oldItem.pageKey.currentState as NestedNavigatorWrapperState)
          .navigatorKey
          .currentState
          ?.popUntil((r) => r.isFirst);
    }

    // 调用 ShowAwarePage 的 onPageShow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      (items[page.index].pageKey.currentState as ShowAwarePage?)?.onPageShow();
    });
  }
}
