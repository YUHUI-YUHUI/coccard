import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coc_character/app/data/dice_roll_record.dart';
import 'package:coc_character/app/setting/dice_history_controller.dart';

void main() {
  group('DiceHistoryController', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('初始为空，加载后仍为空', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = DiceHistoryController(prefs: prefs);
      expect(controller.records, isEmpty);
      expect(controller.length, 0);
    });

    test('addRoll 后历史列表按时间倒序排列', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = DiceHistoryController(prefs: prefs);
      await controller.addRoll(DiceRollRecord(
        diceType: 'D100',
        value: 30,
        createdAt: DateTime(2026, 6, 8, 10, 0),
      ));
      await controller.addRoll(DiceRollRecord(
        diceType: 'D100',
        value: 80,
        createdAt: DateTime(2026, 6, 8, 10, 1),
      ));
      expect(controller.records.first.value, 80);
      expect(controller.records.last.value, 30);
      expect(controller.length, 2);
    });

    test('超过 50 条自动裁剪到 50 条，保留最新', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = DiceHistoryController(prefs: prefs);
      for (var i = 0; i < 55; i++) {
        await controller.addRoll(DiceRollRecord(
          diceType: 'D100',
          value: i + 1,
          createdAt: DateTime(2026, 6, 8, 10, i % 60),
        ));
      }
      expect(controller.length, 50);
      // 最新插入是 i=54，应在首条
      expect(controller.records.first.value, 55);
    });

    test('clear 后列表为空且持久化键被移除', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = DiceHistoryController(prefs: prefs);
      await controller.addRoll(DiceRollRecord(
        diceType: 'D100',
        value: 42,
        createdAt: DateTime(2026, 6, 8, 10, 0),
      ));
      expect(controller.length, 1);
      await controller.clear();
      expect(controller.records, isEmpty);

      // 重新读取应该为空
      final restored = DiceHistoryController(prefs: prefs);
      expect(restored.records, isEmpty);
    });

    test('历史在重启后保留', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = DiceHistoryController(prefs: prefs);
      await controller.addRoll(DiceRollRecord(
        diceType: '3D6',
        value: 12,
        createdAt: DateTime(2026, 6, 8, 12, 0),
        note: '×5 = 60',
      ));
      final restored = DiceHistoryController(prefs: prefs);
      expect(restored.length, 1);
      expect(restored.records.first.diceType, '3D6');
      expect(restored.records.first.note, '×5 = 60');
    });

    test('损坏的 JSON 不会让控制器崩溃', () async {
      SharedPreferences.setMockInitialValues({
        'dice_history_local': 'not-a-json',
      });
      final prefs = await SharedPreferences.getInstance();
      final controller = DiceHistoryController(prefs: prefs);
      expect(controller.records, isEmpty);
    });
  });
}