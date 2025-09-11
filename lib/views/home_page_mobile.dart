import 'package:flutter/material.dart';
import 'package:lzf_music/utils/theme_utils.dart';
import '../widgets/mini_player.dart';
import '../widgets/resolution_display.dart';
import 'package:provider/provider.dart';
import '../../services/theme_provider.dart';
import '../contants/app_contants.dart' show PlayerPage;
import '../router/router.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final menuManager = MenuManager();

  @override
  void initState() {
    super.initState();
    menuManager.init(navigatorKey: GlobalKey<NavigatorState>());
  }

  void _onTabChanged(int newIndex) {
    menuManager.setPage(PlayerPage.values[newIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Consumer<AppThemeProvider>(
      builder: (context, themeProvider, child) {
        final defaultTextColor = ThemeUtils.select(
          context,
          light: Colors.black,
          dark: Colors.white,
        );
        Color sidebarBg = ThemeUtils.backgroundColor(context);
        Color bodyBg = ThemeUtils.backgroundColor(context);
        if (["window", "sidebar"].contains(themeProvider.opacityTarget)) {
          sidebarBg = sidebarBg.withAlpha(
            (255 * themeProvider.seedAlpha).round(),
          );
        }
        if (["window", "body"].contains(themeProvider.opacityTarget)) {
          bodyBg = bodyBg.withAlpha((255 * themeProvider.seedAlpha).round());
        }

        final isMiniPlayerFloating =
            (themeProvider.opacityTarget == 'sidebar' ||
            themeProvider.seedAlpha > 0.98);

        return Scaffold(
          body: Column(
            children: [
              // 主内容区域
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      color: bodyBg,
                      child: isMiniPlayerFloating
                          ? MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                padding: MediaQuery.of(context).padding
                                    .copyWith(
                                      bottom:
                                          MediaQuery.of(
                                            context,
                                          ).padding.bottom +
                                          88, // 增加底部导航栏高度
                                    ),
                              ),
                              child: ValueListenableBuilder<PlayerPage>(
                                valueListenable: menuManager.currentPage,
                                builder: (context, currentPage, _) {
                                  return IndexedStack(
                                    index: currentPage.index,
                                    children: menuManager.pages,
                                  );
                                },
                              ),
                            )
                          : Padding(
                              padding: EdgeInsets.only(bottom: 84 + 80), // 增加底部导航栏高度
                              child: ValueListenableBuilder<PlayerPage>(
                                valueListenable: menuManager.currentPage,
                                builder: (context, currentPage, _) {
                                  return IndexedStack(
                                    index: currentPage.index,
                                    children: menuManager.pages,
                                  );
                                },
                              ),
                            ),
                    ),

                    // 顶部标题栏
                    Positioned(
                      top: 40,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ResolutionDisplay(
                              isMinimized: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // MiniPlayer
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0, // 为底部导航栏留出空间
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return isMiniPlayerFloating
                              ? ClipRect(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: ThemeUtils.backgroundColor(
                                          context,
                                        ).withValues(alpha: 0.6),
                                      ),
                                      child: MiniPlayer(
                                        containerWidth: constraints.maxWidth,
                                        isMobile: true,
                                      ),
                                    ),
                                  ),
                                )
                              : MiniPlayer(
                                  containerWidth: constraints.maxWidth,
                                  isMobile: true,
                                );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // 底部导航栏
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: sidebarBg,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                ),
                child: ValueListenableBuilder<PlayerPage>(
                  valueListenable: menuManager.currentPage,
                  builder: (context, currentPage, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        menuManager.items.length,
                        (index) {
                          final item = menuManager.items[index];
                          final isSelected = index == currentPage.index;
                          
                          Color iconColor;
                          Color textColor;
                          
                          if (isSelected) {
                            iconColor = primary;
                            textColor = primary;
                          } else {
                            iconColor = defaultTextColor.withValues(alpha: 0.6);
                            textColor = defaultTextColor.withValues(alpha: 0.6);
                          }
                          
                          return Expanded(
                            child: InkWell(
                              onTap: () => _onTabChanged(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      item.icon,
                                      color: iconColor,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
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
