import 'package:flutter/material.dart';

import '../data/character_manager.dart';

void showDeleteCharacterDialog({
  required BuildContext context,
  required CharacterManager manager,
  required int index,
  VoidCallback? onDeleted,
}) {
  if (index < 0 || index >= manager.characters.length) {
    return;
  }

  final character = manager.characters[index];
  final characterName = character.name.isEmpty ? '新角色' : character.name;
  final messenger = ScaffoldMessenger.of(context);

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('删除角色卡'),
      content: Text('确定要删除「$characterName」吗？此操作不可恢复。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () async {
            final deleted = await manager.deleteCharacter(index);
            if (deleted == null) return;
            if (!dialogContext.mounted) return;
            Navigator.pop(dialogContext);

            if (!context.mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text('已删除「$characterName」'),
                action: SnackBarAction(
                  label: '撤销',
                  onPressed: () {
                    manager.restoreDeletedCharacter(deleted);
                  },
                ),
              ),
            );
            onDeleted?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('删除'),
        ),
      ],
    ),
  );
}
