import 'package:flutter/material.dart';
import '../database/database.dart';

class SongActionMenu extends StatelessWidget {
  final Song song;
  final VoidCallback? onDelete;
  final VoidCallback? onFavoriteToggle;

  const SongActionMenu({
    super.key,
    required this.song,
    this.onDelete,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      iconSize: 20,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                '删除',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'favorite':
            onFavoriteToggle?.call();
            break;
          case 'delete':
            final confirmed = await _showDeleteConfirmation(context);
            if (confirmed == true) {
              onDelete?.call();
            }
            break;
        }
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除歌曲 "${song.title}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '确定',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  final Song song;
  final VoidCallback? onToggle;

  const FavoriteButton({
    super.key,
    required this.song,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      iconSize: 20,
      icon: Icon(
        song.isFavorite
            ? Icons.favorite_rounded
            : Icons.favorite_outline_rounded,
        color: song.isFavorite ? Colors.red : null,
      ),
    );
  }
}
