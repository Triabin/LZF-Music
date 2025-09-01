import 'package:flutter/material.dart';
import '../widgets/mini_player.dart';

import '../contants/app_contants.dart' show PlayerPage;
import '../router/router.dart';

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
    final brightness = theme.brightness;

    final defaultTextColor = brightness == Brightness.dark
        ? Colors.grey[300]!
        : Colors.grey[800]!;

    return Scaffold(
      body: Row(
        children: [
          // 侧边菜单栏
          ValueListenableBuilder<bool>(
            valueListenable: menuManager.isExtended,
            builder: (context, isExtended, _) {
              return AnimatedContainer(
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
                                          item.icon,
                                          color: textColor,
                                          size: item.iconSize,
                                        ),
                                        Flexible(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            child: isExtended
                                                ? Padding(
                                                    key: const ValueKey('text'),
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
                                                            : FontWeight.normal,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: IconButton(
                        icon: ValueListenableBuilder<bool>(
                          valueListenable: menuManager.isExtended,
                          builder: (context, isExtended, _) {
                            return Icon(
                              isExtended
                                  ? Icons.arrow_back_rounded
                                  : Icons.menu_rounded,
                            );
                          },
                        ),
                        onPressed: () => menuManager.isExtended.value =
                            !menuManager.isExtended.value,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Column(
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
