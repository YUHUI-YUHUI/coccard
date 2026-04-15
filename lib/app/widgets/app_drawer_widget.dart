import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/character_manager.dart';

class AppDrawerWidget extends StatelessWidget {
  const AppDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer<CharacterManager>(
            builder: (context, manager, _) {
              return DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.person, size: 48, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      manager.character.name.isEmpty ? '新角色' : manager.character.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (manager.character.occupation.isNotEmpty)
                      Text(
                        manager.character.occupation,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('创建新角色'),
            onTap: () {
              Navigator.pop(context);
              context.read<CharacterManager>().createNewCharacter();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.switch_account),
            title: const Text('切换角色'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/switch_character');
            },
          ),
          ListTile(
            leading: const Icon(Icons.psychology),
            title: const Text('技能'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/skills');
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('武器'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/weapons');
            },
          ),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text('参考表'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reference');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/about');
            },
          ),
        ],
      ),
    );
  }
}
