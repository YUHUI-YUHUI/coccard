import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'COC 角色卡',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '版本 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text(
              '克苏鲁的呼唤 第七版 角色卡应用',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '基于 Flutter 构建的 COC 7th Edition 角色卡管理应用。'
              '支持角色属性管理、技能追踪、武器管理、骰子系统等功能。'),
            const SizedBox(height: 24),
            const Text(
              '主要功能',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const _FeatureItem(icon: Icons.person, text: '角色属性管理（STR, CON, SIZ, DEX, APP, INT, POW, EDU）'),
            const _FeatureItem(icon: Icons.auto_awesome, text: '技能系统（60+ 技能）'),
            const _FeatureItem(icon: Icons.security, text: '武器管理（200+ 武器数据）'),
            const _FeatureItem(icon: Icons.casino, text: 'D100 骰子系统'),
            const _FeatureItem(icon: Icons.psychology, text: '疯狂发作参考表'),
            const _FeatureItem(icon: Icons.library_books, text: '职业列表（230+ 职业）'),
            const _FeatureItem(icon: Icons.save, text: '本地数据持久化'),
            const SizedBox(height: 24),
            const Text(
              '开发信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('使用 Flutter + Provider + Isar 构建'),
            const Text('数据来源于 COC 7th Edition 官方规则书'),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
