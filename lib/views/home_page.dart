import 'package:flutter/material.dart';
import 'package:lzf_music/utils/theme_utils.dart';
import '../widgets/mini_player.dart';
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
        final defaultTextColor = ThemeUtils.select(context, light: Colors.black, dark: Colors.white);
        Color sidebarBg = ThemeUtils.select(
          context,
          light: themeProvider.lightBg,
          dark: themeProvider.darkBg,
        );
        Color bodyBg = ThemeUtils.select(
          context,
          light: themeProvider.lightBg,
          dark: themeProvider.darkBg,
        );
        if (["window", "sidebar"].contains(themeProvider.opacityTarget)) {
          sidebarBg = sidebarBg.withAlpha(
            (255 * themeProvider.seedAlpha).round(),
          );
        }
        if (["window", "body"].contains(themeProvider.opacityTarget)) {
          bodyBg = bodyBg.withAlpha((255 * themeProvider.seedAlpha).round());
        }

        return Scaffold(
          body: Row(
            children: [
              AnimatedContainer(
                color: sidebarBg,
                duration: const Duration(milliseconds: 200),
                width: themeProvider.sidebarIsExtended ? 220 : 70,
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
                            child: themeProvider.sidebarIsExtended
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
                      child: ValueListenableBuilder<PlayerPage>(
                        valueListenable: menuManager.currentPage,
                        builder: (context, currentPage, _) {
                          return ListView.builder(
                            itemCount: menuManager.items.length,
                            itemBuilder: (context, index) {
                              final item = menuManager.items[index];
                              final isSelected = index == currentPage.index;
                              final isHovered =
                                  index == menuManager.hoverIndex.value;

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
                                onEnter: (_) =>
                                    menuManager.hoverIndex.value = index,
                                onExit: (_) =>
                                    menuManager.hoverIndex.value = -1,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => _onTabChanged(index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            item.icon,
                                            color: textColor,
                                            size: item.iconSize,
                                          ),
                                          Flexible(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              child:
                                                  themeProvider
                                                      .sidebarIsExtended
                                                  ? Padding(
                                                      key: const ValueKey(
                                                        'text',
                                                      ),
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 12,
                                                          ),
                                                      child: Text(
                                                        item.label,
                                                        style: TextStyle(
                                                          color: textColor,
                                                          fontWeight: isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                    .normal,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: IconButton(
                        icon: Icon(
                          themeProvider.sidebarIsExtended
                              ? Icons.arrow_back_rounded
                              : Icons.menu_rounded,
                        ),
                        onPressed: () => themeProvider.toggleExtended(),
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: Stack(
                  children: [
                    Container(color: bodyBg),
                    Column(
                      children: [
                        Expanded(
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
                        // 占位，腾出 MiniPlayer 高度
                        const SizedBox(height: 80),
                      ],
                    ),

                    // 悬浮 MiniPlayer
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: const MiniPlayer(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
