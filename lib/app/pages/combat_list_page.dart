import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/combat_encounter.dart';
import '../setting/combat_controller.dart';

/// 战斗列表页：展示进行中的遭遇与历史战斗，并提供新建入口。
///
/// 战斗追踪器 Step 3（提案 docs/feature-proposals/2026-06-18-战斗追踪器.md）。
/// 打开某场战斗的详情页将在 Step 4（CombatPage）接入，本步先以占位提示替代。
class CombatListPage extends StatelessWidget {
  const CombatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CombatController>();
    final current = controller.currentEncounter;
    final history = controller.history;
    final isEmpty = current == null && history.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('战斗追踪器')),
      body: isEmpty
          ? _buildEmpty(context)
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                if (current != null) ...[
                  const _SectionHeader(label: '进行中的战斗'),
                  _EncounterCard(
                    encounter: current,
                    ongoing: true,
                    onOpen: () => _openEncounter(context),
                    onFinish: () => _confirmFinish(context),
                  ),
                  const SizedBox(height: 16),
                ],
                if (history.isNotEmpty) ...[
                  _SectionHeader(label: '历史战斗（${history.length}）'),
                  ...history.map((e) => _EncounterCard(
                        encounter: e,
                        ongoing: false,
                        onOpen: () => _openEncounter(context),
                      )),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewBattleDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('新建战斗'),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 64, color: scheme.outlineVariant),
          const SizedBox(height: 12),
          Text('暂无战斗记录', style: TextStyle(color: scheme.outline)),
          const SizedBox(height: 4),
          Text(
            '点击右下角「新建战斗」开始追踪',
            style: TextStyle(fontSize: 12, color: scheme.outline),
          ),
        ],
      ),
    );
  }

  // 占位：战斗详情页（CombatPage）在 Step 4 接入后替换为路由跳转。
  void _openEncounter(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('战斗详情页开发中（Step 4）')),
    );
  }

  Future<void> _showNewBattleDialog(BuildContext context) async {
    final controller = context.read<CombatController>();
    final hasOngoing = controller.currentEncounter != null;
    final nameController = TextEditingController(text: '新的战斗');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建战斗'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '战斗名称',
                hintText: '如：图书馆遭遇战',
              ),
              onSubmitted: (_) => Navigator.pop(ctx, true),
            ),
            if (hasOngoing) ...[
              const SizedBox(height: 12),
              Text(
                '已有一场进行中的战斗，新建后将丢弃当前战斗（未结束的战斗不会进入历史）。',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final name = nameController.text.trim();
    // 一期先创建空遭遇，参战者通过 Step 4/5 的添加入口加入。
    controller.createEncounter(name.isEmpty ? '未命名战斗' : name, []);
    if (!context.mounted) return;
    _openEncounter(context);
  }

  Future<void> _confirmFinish(BuildContext context) async {
    final controller = context.read<CombatController>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('结束战斗'),
        content: const Text('将当前战斗标记为已结束并移入历史，确认？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('结束'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    controller.finishEncounter();
  }
}

/// 分区标题。
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

/// 单场战斗卡片。
class _EncounterCard extends StatelessWidget {
  const _EncounterCard({
    required this.encounter,
    required this.ongoing,
    this.onOpen,
    this.onFinish,
  });

  final CombatEncounter encounter;
  final bool ongoing;
  final VoidCallback? onOpen;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = ongoing
        ? '第 ${encounter.currentRound} 轮 · ${encounter.combatants.length} 名参战者'
        : '${encounter.totalRounds} 轮 · ${encounter.combatants.length} 名参战者'
            '${encounter.finishedAt != null ? ' · ${_fmtDate(encounter.finishedAt!)}' : ''}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                ongoing ? Icons.local_fire_department : Icons.history,
                color: ongoing ? scheme.primary : scheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            encounter.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(ongoing: ongoing),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: scheme.outline),
                    ),
                  ],
                ),
              ),
              if (ongoing && onFinish != null)
                TextButton(
                  onPressed: onFinish,
                  child: const Text('结束'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDate(DateTime t) {
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}

/// 进行中 / 已结束 状态徽标。
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.ongoing});

  final bool ongoing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = ongoing ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = ongoing ? scheme.onPrimaryContainer : scheme.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        ongoing ? '进行中' : '已结束',
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }
}
