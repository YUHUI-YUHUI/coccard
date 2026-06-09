import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dice_roll_record.dart';
import '../setting/dice_history_controller.dart';

/// 本地投骰工具。结果仅保存在当前设备，不会上传或同步给其他玩家。
class DiceRollerWidget extends StatefulWidget {
  const DiceRollerWidget({super.key});

  @override
  State<DiceRollerWidget> createState() => _DiceRollerWidgetState();
}

class _DiceRollerWidgetState extends State<DiceRollerWidget> {
  final Random _random = Random();
  int _d100Result = 0;
  int _d6Result = 0;

  static const int _historyPreview = 8;

  static String _formatTime(DateTime t) {
    final local = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<DiceHistoryController>().records;
    return SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎲 本地投骰子',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '结果仅保存在本机，不会上传给其他玩家',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const Text('D100 技能检定',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _rollD100,
                  icon: const Icon(Icons.casino),
                  label: const Text('投掷 D100'),
                ),
                if (_d100Result > 0) ...[
                  const SizedBox(height: 12),
                  Text('$_d100Result',
                      style: const TextStyle(
                          fontSize: 40, fontWeight: FontWeight.bold)),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const Text('3D6 属性生成',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _roll3D6,
                  icon: const Icon(Icons.casino),
                  label: const Text('投掷 3D6'),
                ),
                if (_d6Result > 0) ...[
                  const SizedBox(height: 12),
                  Text('$_d6Result  (×5 = ${_d6Result * 5})',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 12),
          _buildHistoryCard(history),
        ]),
      ),
    );
  }

  Widget _buildHistoryCard(List<DiceRollRecord> history) {
    final preview = history.take(_historyPreview).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.history, size: 18),
            const SizedBox(width: 6),
            const Text('本地骰点历史',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            if (history.isNotEmpty)
              TextButton(
                onPressed: _confirmClearHistory,
                child: const Text('清空'),
              ),
          ]),
          const SizedBox(height: 8),
          if (preview.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('暂无本地记录，掷出第一个骰子吧',
                  style: TextStyle(color: Colors.grey.shade600)),
            )
          else
            ...preview.map((r) => _historyTile(record: r)),
          if (history.length > _historyPreview)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('仅展示最近 $_historyPreview 条，共 ${history.length} 条',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ),
        ]),
      ),
    );
  }

  Widget _historyTile({required DiceRollRecord record}) {
    final time = _formatTime(record.createdAt);
    final note = record.note;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
          width: 64,
          child: Text(record.diceType,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          width: 40,
          child: Text('${record.value}',
              style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          child: Text(
            note ?? '—',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
        Text(time, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ]),
    );
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空本地骰点历史'),
        content: const Text('将清除本机最近 50 条本地投骰记录，技能成长统计不会受影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<DiceHistoryController>().clear();
  }

  void _rollD100() {
    final value = _random.nextInt(100) + 1;
    setState(() => _d100Result = value);
    context.read<DiceHistoryController>().addRoll(
          DiceRollRecord(
            diceType: 'D100',
            value: value,
            createdAt: DateTime.now(),
          ),
        );
  }

  void _roll3D6() {
    final value = _random.nextInt(6) +
        1 +
        _random.nextInt(6) +
        1 +
        _random.nextInt(6) +
        1;
    setState(() => _d6Result = value);
    context.read<DiceHistoryController>().addRoll(
          DiceRollRecord(
            diceType: '3D6',
            value: value,
            createdAt: DateTime.now(),
            note: '×5 = ${value * 5}',
          ),
        );
  }
}