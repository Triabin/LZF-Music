import 'package:flutter/material.dart';

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
            // NavigationHelper.navigateBack(context);
          },
        ),
      ),
      body: const Center(
        child: Text('存储设置页面内容'),
      ),
    );
  }
}