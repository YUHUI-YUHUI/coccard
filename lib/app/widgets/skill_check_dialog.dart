import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/character_manager.dart';
import '../data/check_rule.dart';
import '../setting/check_rule_controller.dart';

const D100CheckEvaluator _evaluator = D100CheckEvaluator();

/// 执行技能检定并展示与技能页一致的结果、日志和幸运补正流程。
Future<void> showSkillCheckDialog({
  required BuildContext context,
  required CharacterManager manager,
  required String skillName,
  required int skillValue,
  Random? random,
}) async {
  final roll = (random ?? Random()).nextInt(100) + 1;
  final rule = context.read<CheckRuleController>().profile;
  final result = _evaluator.evaluate(
    target: skillValue,
    roll: roll,
    rule: rule,
  );
  manager.recordSkillCheck(result, skillName);

  final luckCost = result.luckCost;
  final currentLuck = manager.character.luck;
  final canSpendLuck = rule.allowSpendLuck &&
      result.canUseLuck &&
      luckCost > 0 &&
      luckCost <= currentLuck;
  final resultColor = result.isSuccess
      ? Theme.of(context).colorScheme.tertiary
      : Theme.of(context).colorScheme.error;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('$skillName 检定'),
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
              color: resultColor,
            ),
          ),
          Text(
            result.resultText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: resultColor,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _checkInfoChip('目标', '${result.skillValue}%'),
              _checkInfoChip('困难', '${result.hardValue}%'),
              _checkInfoChip('极难', '${result.extremeValue}%'),
              _checkInfoChip('当前幸运', '$currentLuck'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '规则：${rule.name}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (!result.isSuccess) ...[
            const SizedBox(height: 16),
            Text(
              _luckHintText(result, currentLuck, rule),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (canSpendLuck)
          TextButton.icon(
            onPressed: () {
              final spent = manager.spendLuck(luckCost);
              if (spent) {
                manager.markLastCheckLuckSpent(
                  skillName: skillName,
                  luckCost: luckCost,
                );
              }
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    spent ? '已花费 $luckCost 幸运，补成普通成功' : '幸运不足，无法补正',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.star),
            label: Text('花费 $luckCost 幸运'),
          ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}

Widget _checkInfoChip(String label, String value) {
  return Chip(
    visualDensity: VisualDensity.compact,
    label: Text('$label $value'),
  );
}

String _luckHintText(
  SkillCheckResult result,
  int currentLuck,
  CheckRuleProfile rule,
) {
  if (result.level == SkillCheckLevel.fumble) {
    return '大失败不能通过花费幸运补正';
  }
  if (!rule.allowSpendLuck) {
    return '当前规则禁用幸运补正';
  }

  final cost = result.luckCost;
  if (cost <= 0) return '';
  if (cost <= currentLuck) {
    return '可花费 $cost 点幸运，将结果补成普通成功';
  }
  return '需要 $cost 点幸运才能补成普通成功，当前幸运不足';
}
