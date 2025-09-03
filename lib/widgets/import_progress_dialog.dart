import 'package:flutter/material.dart';

class ImportProgressDialog extends StatefulWidget {
  final int totalFiles;
  final int processedFiles;
  final String? currentFileName;
  final bool isScanning;
  final VoidCallback? onCancel;

  const ImportProgressDialog({
    super.key,
    this.totalFiles = 0,
    this.processedFiles = 0,
    this.currentFileName,
    this.isScanning = true,
    this.onCancel,
  });

  @override
  State<ImportProgressDialog> createState() => _ImportProgressDialogState();
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
                  Text('正在扫描文件夹...'),
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
                      const Text('处理进度'),
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
            if (widget.currentFileName != null && widget.currentFileName!.isNotEmpty) ...[
              const Text(
                '当前文件:',
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
                  widget.currentFileName!,
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
            child: const Text('取消'),
          ),
      ],
    );
  }
}

// 可动态更新的进度对话框包装器
class DynamicImportProgressDialog extends StatefulWidget {
  const DynamicImportProgressDialog({super.key});

  @override
  State<DynamicImportProgressDialog> createState() => DynamicImportProgressDialogState();
}

class DynamicImportProgressDialogState extends State<DynamicImportProgressDialog> {
  int _totalFiles = 0;
  int _processedFiles = 0;
  String? _currentFileName;
  bool _isScanning = true;

  // 更新进度的方法
  void updateProgress({
    int? totalFiles,
    int? processedFiles,
    String? currentFileName,
    bool? isScanning,
  }) {
    if (mounted) {
      setState(() {
        if (totalFiles != null) _totalFiles = totalFiles;
        if (processedFiles != null) _processedFiles = processedFiles;
        if (currentFileName != null) _currentFileName = currentFileName;
        if (isScanning != null) _isScanning = isScanning;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ImportProgressDialog(
      totalFiles: _totalFiles,
      processedFiles: _processedFiles,
      currentFileName: _currentFileName,
      isScanning: _isScanning,
      onCancel: () {
        Navigator.of(context).pop();
      },
    );
  }
}