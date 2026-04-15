import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/character_manager.dart';

class SwitchCharacterPage extends StatelessWidget {
  const SwitchCharacterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('切换角色'),
      ),
      body: Consumer<CharacterManager>(
        builder: (context, manager, _) {
          final characters = manager.characters;

          if (characters.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无角色'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      manager.createNewCharacter();
                      Navigator.pop(context);
                    },
                    child: const Text('创建新角色'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: characters.length,
            itemBuilder: (context, index) {
              final character = characters[index];
              final isSelected = character.id == manager.character.id;

              return Card(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(character.name.isEmpty ? '?' : character.name[0]),
                  ),
                  title: Text(character.name.isEmpty ? '新角色' : character.name),
                  subtitle: Text(character.occupation.isEmpty ? '未选择职业' : character.occupation),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    manager.selectCharacter(character.id);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<CharacterManager>().createNewCharacter();
          Navigator.pop(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
