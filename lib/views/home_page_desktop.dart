import 'package:flutter/material.dart';
import 'package:lzf_music/utils/theme_utils.dart';
import '../widgets/mini_player.dart';
import '../widgets/resolution_display.dart';
import 'package:provider/provider.dart';
import '../../services/theme_provider.dart';
import '../contants/app_contants.dart' show PlayerPage;
import '../router/router.dart';
import 'dart:ui';

class HomePageDesktop extends StatefulWidget {
  const HomePageDesktop({super.key});

  @override
  State<HomePageDesktop> createState() => _HomePageDesktopState();
}

class _HomePageDesktopState extends State<HomePageDesktop> {
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
                                bgColor = primary.withValues(alpha: 0.2);
                                textColor = primary;
                              } else if (isHovered) {
                                bgColor = Colors.grey.withValues(alpha: 0.2);
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
                    // 主内容区域
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
                                          88,
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
                              padding: EdgeInsets.only(bottom: 84),
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

                    // 逻辑分辨率显示
                    // Positioned(
                    //   top: 8,
                    //   right: 8,
                    //   child: ResolutionDisplay(
                    //     isMinimized: true,
                    //   ),
                    // ),

                    // MiniPlayer
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
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
                                      ),
                                    ),
                                  ),
                                )
                              : MiniPlayer(
                                  containerWidth: constraints.maxWidth,
                                );
                        },
                      ),
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

class BlurWrapper extends StatelessWidget {
  final Widget child;
  final double sigma;
  final Color overlayColor;

  const BlurWrapper({
    super.key,
    required this.child,
    this.sigma = 10,
    this.overlayColor = const Color(0x33000000),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BlurPainter(sigma: sigma, overlayColor: overlayColor),
      child: child,
    );
  }
}

class _BlurPainter extends CustomPainter {
  final double sigma;
  final Color overlayColor;

  _BlurPainter({required this.sigma, required this.overlayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 开一个离屏缓冲区
    canvas.saveLayer(rect, Paint());

    // 背景模糊
    final blurPaint = Paint()
      ..imageFilter = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
    canvas.saveLayer(rect, blurPaint);

    // 叠一层半透明色（类似毛玻璃颜色）
    canvas.drawRect(rect, Paint()..color = overlayColor);

    // 合并回主画布
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
