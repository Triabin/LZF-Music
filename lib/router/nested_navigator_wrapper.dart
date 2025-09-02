import 'package:flutter/material.dart';
import '../widgets/show_aware_page.dart';
/// 通用的 Navigator 包装器
class NestedNavigatorWrapper extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final String initialRoute;
  final Map<String, WidgetBuilder> routes;

  const NestedNavigatorWrapper({
    super.key,
    required this.navigatorKey,
    required this.initialRoute,
    required this.routes,
  });

  @override
  State<NestedNavigatorWrapper> createState() => NestedNavigatorWrapperState();
}

class NestedNavigatorWrapperState extends State<NestedNavigatorWrapper> with ShowAwarePage {
  GlobalKey<NavigatorState> get navigatorKey => widget.navigatorKey;

    @override
  void onPageShow() {
  final navigator = widget.navigatorKey.currentState;
  if (navigator == null) return;

  final currentRoute = navigator.overlay?.context;
  if (currentRoute != null) {
    final state = currentRoute.findAncestorStateOfType<ShowAwarePage>();
    if (state != null && state != this) {
      state.onPageShow();
    }
  }
}
  
  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: widget.navigatorKey,
      initialRoute: widget.initialRoute,
      onGenerateRoute: (settings) {
        final builder = widget.routes[settings.name];
        if (builder != null) {
          return MaterialPageRoute(
            builder: builder,
            settings: settings,
          );
        }
        // 默认 fallback 到 initialRoute
        return MaterialPageRoute(
          builder: widget.routes[widget.initialRoute]!,
          settings: RouteSettings(name: widget.initialRoute),
        );
      },
    );
  }
}

/// 通用的导航辅助类
class NestedNavigationHelper {
  static void push(BuildContext context, String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  static void pop(BuildContext context) {
    Navigator.of(context).pop();
  }
}