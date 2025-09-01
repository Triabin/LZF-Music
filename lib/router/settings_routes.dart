import 'package:flutter/material.dart';
import '../views/settings/settings_page.dart';
import '../views/settings/storage_setting_page.dart';

final settingsRoutes = <String, WidgetBuilder>{
  '/settings': (context) => const SettingsPage(),
  '/storage-settings': (context) => const StorageSettingPage(),
};