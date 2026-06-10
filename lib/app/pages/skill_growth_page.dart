import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/character_manager.dart';
import '../data/skill_check_record.dart';

/// 幕间技能成长批量处理页。
///
/// 列出当前角色所有 [SkillGrowthState.growthMarked] 为 true 的技能，
/// 玩家可逐个或一次性掷 1D100 检定：roll > skillValue 即成长 +1D10。
class SkillGrowthPage extends StatefulWidget {
  const SkillGrowthPage({super.key});

  @override
  State<SkillGrowthPage> createState() => _SkillGrowthPageState();
}

class _SkillGrowthPageState extends State<SkillGrowthPage> {
  /// 缓存最近一次的成长结果，用于在对话框里展示。
  final Map<String, SkillGrowthCheck> _lastResults = {};

  Future<void> _rollOne(
    BuildContext context,
    CharacterManager manager,
    String skillName,
  ) async {
    try {
      final result = manager.performGrowthCheck(skillName);
      if (!mounted) return;
      setState(() {
        _lastResults[skillName] = result;
      });
      _showResultDialog(context, skillName, result);
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _rollAll(
    BuildContext context,
    CharacterManager manager,
  ) async {
    final marked = manager.markedGrowthSkills();
    if (marked.isEmpty) return;

    final results = <String, SkillGrowthCheck>{};
    var grownCount = 0;
    for (final entry in marked) {
      try {
        final r = manager.performGrowthCheck(entry.skillName);
        results[entry.skillName] = r;
        if (r.grown) grownCount += 1;
      } on StateError {
        // 跳过已被其他流程清除的标记
      }
    }
    if (!mounted) return;
    setState(() {
      _lastResults.addAll(results);
    });
    _showBatchSummaryDialog(context, marked.length, grownCount, results);
  }

  void _showResultDialog(
    BuildContext context,
    String skillName,
    SkillGrowthCheck result,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final color = result.grown ? scheme.tertiary : scheme.error;
    final title = result.grown ? '✨ 成长成功' : '未成长';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$title · $skillName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${result.roll}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.grown
                  ? '掷出 ${result.roll} > ${result.skillValue}，+${result.increase}'
                  : '掷出 ${result.roll} ≤ ${result.skillValue}，未成长',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (result.grown)
              Text(
                '新值：${result.skillValue} → ${result.newSkillValue}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              )
            else
              Text(
                '技能值保持 ${result.skillValue}，成长标记保留',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showBatchSummaryDialog(
    BuildContext context,
    int total,
    int grownCount,
    Map<String, SkillGrowthCheck> results,
  ) {
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('幕间成长批量检定'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '本次共检定 $total 项，成长 $grownCount 项',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (_, i) {
                    final skillName = results.keys.elementAt(i);
                    final r = results[skillName]!;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(skillName),
                      subtitle: Text(
                        '投 ${r.roll} / 当前 ${r.skillValue}',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      trailing: Text(
                        r.grown ? '+${r.increase}' : '—',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: r.grown ? scheme.tertiary : scheme.outline,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('幕间技能成长'),
        actions: [
          Consumer<CharacterManager>(
            builder: (context, manager, _) {
              final hasMarked = manager.markedGrowthSkills().isNotEmpty;
              return TextButton.icon(
                onPressed: hasMarked
                    ? () => _rollAll(context, manager)
                    : null,
                icon: const Icon(Icons.casino),
                label: const Text('全部检定'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CharacterManager>(
        builder: (context, manager, _) {
          final marked = manager.markedGrowthSkills();
          if (marked.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: marked.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = marked[index];
              return _GrowthSkillCard(
                skillName: entry.skillName,
                state: entry.state,
                skillValue:
                    manager.character.skills[entry.skillName] ?? 0,
                lastResult: _lastResults[entry.skillName],
                onRoll: () => _rollOne(context, manager, entry.skillName),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 64,
              color: scheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '当前没有待成长技能',
              style: TextStyle(
                fontSize: 18,
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在技能页完成成功的检定后，技能会自动标记成长。'
              '回到这里掷 1D100 检定，掷出大于当前技能值即成长 +1D10。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowthSkillCard extends StatelessWidget {
  const _GrowthSkillCard({
    required this.skillName,
    required this.state,
    required this.skillValue,
    required this.lastResult,
    required this.onRoll,
  });

  final String skillName;
  final SkillGrowthState state;
  final int skillValue;
  final SkillGrowthCheck? lastResult;
  final VoidCallback onRoll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final grown = lastResult?.grown;
    final cardColor = grown == null
        ? scheme.surfaceContainerHighest
        : (grown
            ? scheme.tertiaryContainer
            : scheme.surfaceContainerHighest);

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skillName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _miniChip(
                        '成功 ${state.successCount}',
                        scheme.tertiary,
                      ),
                      _miniChip(
                        '失败 ${state.failureCount}',
                        scheme.error,
                      ),
                      if (state.lastGrowthAt != null)
                        _miniChip(
                          '上次成长 ${_formatDate(state.lastGrowthAt!)}',
                          scheme.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '当前技能值 $skillValue%（需掷出 > $skillValue）',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (lastResult != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      lastResult!.grown
                          ? '本次投 ${lastResult!.roll}，+${lastResult!.increase} → ${lastResult!.newSkillValue}'
                          : '本次投 ${lastResult!.roll}，未成长',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: grown! ? scheme.tertiary : scheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Text(
                  '$skillValue%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                FilledButton.icon(
                  onPressed: onRoll,
                  icon: const Icon(Icons.casino, size: 18),
                  label: const Text('1D100'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
