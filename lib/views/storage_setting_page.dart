// 在你的 SettingsPage 中这样使用：

import 'package:flutter/material.dart';

import 'home_page.dart';

// 在 StorageSettingPage 中使用返回功能：
class StorageSettingPage extends StatelessWidget {
  const StorageSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('存储设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            NavigationHelper.navigateBack(context);
          },
        ),
      ),
      body: const Center(
        child: Text('存储设置页面内容'),
      ),
    );
  }
}