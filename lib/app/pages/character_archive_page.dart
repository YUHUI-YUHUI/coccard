import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/character.dart';
import '../data/character_manager.dart';
import '../widgets/character_portrait.dart';

class CharacterArchivePage extends StatelessWidget {
  const CharacterArchivePage({super.key});

  static const _unassignedModule = '未关联模组';
  static const moduleStatuses = ['待开团', '进行中', '已结团'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('人物卡与模组'),
      ),
      body: Consumer<CharacterManager>(
        builder: (context, manager, _) {
          if (manager.characters.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64),
                  SizedBox(height: 12),
                  Text('还没有可整理的人物卡'),
                ],
              ),
            );
          }

          final groups = <String, List<Character>>{};
          for (final character in manager.characters) {
            final module = character.moduleName.trim().isEmpty
                ? _unassignedModule
                : character.moduleName.trim();
            groups.putIfAbsent(module, () => []).add(character);
          }
          final moduleNames = groups.keys.toList()
            ..sort((a, b) {
              if (a == _unassignedModule) return 1;
              if (b == _unassignedModule) return -1;
              return a.compareTo(b);
            });

          return ListView.builder(
            key: const Key('character_archive_list'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: moduleNames.length,
            itemBuilder: (context, index) {
              final moduleName = moduleNames[index];
              final characters = groups[moduleName]!;
              return _ModuleSection(
                moduleName: moduleName,
                characters: characters,
                currentCharacterId: manager.character.id,
                onEdit: (character) =>
                    _showModuleDialog(context, manager, character),
                onSelect: (character) async {
                  await manager.selectCharacter(character.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已切换到 ${_displayName(character)}')),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create_character'),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('新建人物卡'),
      ),
    );
  }

  static String _displayName(Character character) =>
      character.name.trim().isEmpty ? '未命名 PC' : character.name.trim();

  Future<void> _showModuleDialog(
    BuildContext context,
    CharacterManager manager,
    Character character,
  ) async {
    final controller = TextEditingController(text: character.moduleName);
    var status = moduleStatuses.contains(character.moduleStatus)
        ? character.moduleStatus
        : '进行中';

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('整理 ${_displayName(character)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const Key('module_name_field'),
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '所属模组',
                    hintText: '例如：无名之城',
                    helperText: '同名模组的人物卡会自动归在一起',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('module_status_field'),
                  value: status,
                  decoration: const InputDecoration(
                    labelText: '模组状态',
                    border: OutlineInputBorder(),
                  ),
                  items: moduleStatuses
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => status = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              key: const Key('save_module_button'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (shouldSave == true) {
      await manager.updateCharacterModule(
        character.id,
        moduleName: controller.text,
        moduleStatus: status,
      );
    }
  }
}

class _ModuleSection extends StatelessWidget {
  final String moduleName;
  final List<Character> characters;
  final int currentCharacterId;
  final ValueChanged<Character> onEdit;
  final ValueChanged<Character> onSelect;

  const _ModuleSection({
    required this.moduleName,
    required this.characters,
    required this.currentCharacterId,
    required this.onEdit,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_outlined, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  moduleName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Text('${characters.length} 张'),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 960
                  ? 4
                  : constraints.maxWidth >= 640
                      ? 3
                      : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: characters.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (context, index) {
                  final character = characters[index];
                  return _CharacterArchiveCard(
                    character: character,
                    isCurrent: character.id == currentCharacterId,
                    onEdit: () => onEdit(character),
                    onSelect: () => onSelect(character),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CharacterArchiveCard extends StatelessWidget {
  final Character character;
  final bool isCurrent;
  final VoidCallback onEdit;
  final VoidCallback onSelect;

  const _CharacterArchiveCard({
    required this.character,
    required this.isCurrent,
    required this.onEdit,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = CharacterArchivePage._displayName(character);
    return Card(
      key: ValueKey('character_archive_card_${character.id}'),
      clipBehavior: Clip.antiAlias,
      color: isCurrent ? colors.primaryContainer : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => Dialog(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 520, maxHeight: 720),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CharacterPortrait(
                          character: character,
                          borderRadius: 24,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filledTonal(
                            tooltip: '关闭',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CharacterPortrait(
                    character: character,
                    borderRadius: 0,
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        character.moduleStatus,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  key: ValueKey('edit_module_${character.id}'),
                  tooltip: '编辑模组对应',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(Icons.drive_file_rename_outline),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              character.occupation.isEmpty ? '未设置职业' : character.occupation,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: FilledButton.tonalIcon(
              onPressed: isCurrent ? null : onSelect,
              icon: Icon(isCurrent ? Icons.check : Icons.switch_account),
              label: Text(isCurrent ? '当前人物卡' : '切换使用'),
            ),
          ),
        ],
      ),
    );
  }
}
