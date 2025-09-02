import 'package:flutter/material.dart';
import '../../widgets/show_aware_page.dart';
class StorageSettingPage extends StatefulWidget {
  const StorageSettingPage({super.key});

  @override
  StorageSettingPageState createState() => StorageSettingPageState();
}

class StorageSettingPageState extends State<StorageSettingPage> with ShowAwarePage {
  @override
  void onPageShow() {
    print('StorageSettingPage is shown');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('存储设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {},
        ),
      ),
      body: const Center(
        child: Text('存储设置页面内容'),
      ),
    );
  }
}