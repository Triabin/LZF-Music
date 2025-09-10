import 'package:flutter/material.dart';

class ThemeUtils {
  ThemeUtils._();

  static const Color lightBg = Color(0xffededed);
  static const Color darkBg = Color(0xff191919);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static bool isLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light;
  }

  static T select<T>(
    BuildContext context, {
    required T light,
    required T dark,
  }) {
    return isDark(context) ? dark : light;
  }

  static Color backgroundColor(BuildContext context) {
    return select(context, light: lightBg, dark: darkBg);
  }
}