import 'package:flutter/material.dart';

// 导入进度回调函数类型定义
typedef ImportProgressCallback = void Function({
  int? totalFiles,
  int? processedFiles,
  String? failedFileName,
  bool? isScanning,
  bool? isCompleted,
});

class ImportProgressDialog extends StatefulWidget {
  final int totalFiles;
  final int processedFiles;
  final String? failedFileName;
  final bool isScanning;
  final bool isCompleted;
  final VoidCallback? onCancel;

  const ImportProgressDialog({
    super.key,
    this.totalFiles = 0,
    this.processedFiles = 0,
    this.failedFileName,
    this.isScanning = true,
    this.isCompleted = false,
    this.onCancel,
  });

  @override
  State<ImportProgressDialog> createState() => _ImportProgressDialogState();

  // 静态方法：显示导入进度对话框并返回更新函数
  static Future<ImportProgressCallback> showImportDialog(
    BuildContext context, {
    VoidCallback? onCancel,
  }) async {
    final GlobalKey<DynamicImportProgressDialogState> dialogKey = 
        GlobalKey<DynamicImportProgressDialogState>();

    // 显示对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DynamicImportProgressDialog(
        key: dialogKey,
        onCancel: onCancel,
      ),
    );

    // 等待对话框完全构建
    await Future.delayed(const Duration(milliseconds: 100));

    // 返回更新函数
    return ({
      int? totalFiles,
      int? processedFiles,
      String? failedFileName,
      bool? isScanning,
      bool? isCompleted,
    }) {
      dialogKey.currentState?.updateProgress(
        totalFiles: totalFiles,
        processedFiles: processedFiles,
        failedFileName: failedFileName,
        isScanning: isScanning,
        isCompleted: isCompleted,
      );
    };
  }

  // 静态方法：关闭导入进度对话框
  static void closeImportDialog(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

class _ImportProgressDialogState extends State<ImportProgressDialog> {
  @override
  Widget build(BuildContext context) {
    final progress = widget.totalFiles > 0 ? widget.processedFiles / widget.totalFiles : 0.0;
    
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.library_music_rounded),
          SizedBox(width: 8),
          Text('导入音乐文件'),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isScanning) ...[
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('正在扫描音乐文件...'),
                ],
              ),
            ] else ...[
              // 显示进度条
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('导入进度'),
                      Text('${widget.processedFiles}/${widget.totalFiles}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // 显示当前处理的文件
            if (widget.failedFileName != null && widget.failedFileName!.isNotEmpty) ...[
              const Text(
                '未导入文件：',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.failedFileName!,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.onCancel != null)
          TextButton(
            onPressed: widget.onCancel,
            child: Text(widget.isCompleted ? '确认' : '取消'),
          ),
      ],
    );
  }
}

// 可动态更新的进度对话框包装器
class DynamicImportProgressDialog extends StatefulWidget {
  final VoidCallback? onCancel;

  const DynamicImportProgressDialog({
    super.key,
    this.onCancel,
  });

  @override
  State<DynamicImportProgressDialog> createState() => DynamicImportProgressDialogState();
}

class DynamicImportProgressDialogState extends State<DynamicImportProgressDialog> {
  int _totalFiles = 0;
  int _processedFiles = 0;
  String? _failedFileName;
  bool _isScanning = true;
  bool _isCompleted = false;

  // 更新进度的方法
  void updateProgress({
    int? totalFiles,
    int? processedFiles,
    String? failedFileName,
    bool? isScanning,
    bool? isCompleted,
  }) {
    if (mounted) {
      setState(() {
        if (totalFiles != null) _totalFiles = totalFiles;
        if (processedFiles != null) _processedFiles = processedFiles;
        if (failedFileName != null) _failedFileName = failedFileName;
        if (isScanning != null) _isScanning = isScanning;
        if (isCompleted != null) _isCompleted = isCompleted;
      });
    }
  }

  // 开始扫描
  void startScanning() {
    updateProgress(isScanning: true);
  }

  // 开始导入
  void startImporting(int totalFiles) {
    updateProgress(
      totalFiles: totalFiles,
      processedFiles: 0,
      isScanning: false,
    );
  }

  // 更新导入进度
  void updateImportProgress(int processedFiles, String failedFileName) {
    updateProgress(
      processedFiles: processedFiles,
      failedFileName: failedFileName,
    );
  }

  // 完成导入
  void completeImport() {
    updateProgress(
      processedFiles: _totalFiles,
      failedFileName: '导入完成',
      isCompleted: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ImportProgressDialog(
      totalFiles: _totalFiles,
      processedFiles: _processedFiles,
      failedFileName: _failedFileName,
      isScanning: _isScanning,
      isCompleted: _isCompleted,
      onCancel: widget.onCancel ?? () {
        Navigator.of(context).pop();
      },
    );
  }
}