import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coc_character/app/data/combat_encounter.dart';
import 'package:coc_character/app/setting/combat_controller.dart';

void main() {
  group('CombatController', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    Combatant makeCombatant(String id, String name, int dex, int maxHp,
        {CombatantType type = CombatantType.npc}) {
      return Combatant(
        id: id,
        name: name,
        type: type,
        dex: dex,
        maxHp: maxHp,
        currentHp: maxHp,
      );
    }

    test('After creating encounter, currentEncounter is not null', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = CombatController(prefs: prefs);

      expect(controller.currentEncounter, isNull);

      controller.createEncounter('Test Battle', [
        makeCombatant('c1', 'Alice', 15, 30),
        makeCombatant('c2', 'Bob', 10, 20),
      ]);

      expect(controller.currentEncounter, isNotNull);
      expect(controller.currentEncounter!.name, 'Test Battle');
      expect(controller.currentEncounter!.combatants.length, 2);
      // 应按 DEX 降序排列
      expect(controller.currentEncounter!.combatants[0].name, 'Alice');
      expect(controller.currentEncounter!.combatants[1].name, 'Bob');
    });

    test('modifyHp correctly updates currentHp and damageTaken', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = CombatController(prefs: prefs);

      controller.createEncounter('Battle', [
        makeCombatant('c1', 'Alice', 15, 30),
      ]);

      final combatant = controller.currentEncounter!.combatants[0];
      expect(combatant.currentHp, 30);
      expect(combatant.damageTaken, 0);
      expect(combatant.isAlive, true);

      // 造成 12 点伤害
      controller.modifyHp('c1', -12);
      expect(combatant.currentHp, 18);
      expect(combatant.damageTaken, 12);
      expect(combatant.isAlive, true);

      // 治疗 5 点（damageTaken 不应减少）
      controller.modifyHp('c1', 5);
      expect(combatant.currentHp, 23);
      expect(combatant.damageTaken, 12);

      // 伤害超过当前 HP，应 clamp 到 0
      controller.modifyHp('c1', -100);
      expect(combatant.currentHp, 0);
      expect(combatant.damageTaken, 12 + 23);
      expect(combatant.isAlive, false);
      expect(combatant.isUnconscious, true);
    });

    test('nextTurn advances index, nextRound advances round when reaching end',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = CombatController(prefs: prefs);

      controller.createEncounter('Battle', [
        makeCombatant('c1', 'Alice', 15, 30),
        makeCombatant('c2', 'Bob', 10, 20),
        makeCombatant('c3', 'Carol', 5, 25),
      ]);

      expect(controller.currentEncounter!.currentRound, 1);
      expect(controller.currentEncounter!.currentTurnIndex, 0);

      controller.nextTurn();
      expect(controller.currentEncounter!.currentTurnIndex, 1);

      controller.nextTurn();
      expect(controller.currentEncounter!.currentTurnIndex, 2);

      // 再 nextTurn 应触发 nextRound
      controller.nextTurn();
      expect(controller.currentEncounter!.currentRound, 2);
      expect(controller.currentEncounter!.currentTurnIndex, 0);
    });

    test('toggleStatus toggles status tags', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = CombatController(prefs: prefs);

      controller.createEncounter('Battle', [
        makeCombatant('c1', 'Alice', 15, 30),
      ]);

      final combatant = controller.currentEncounter!.combatants[0];
      expect(combatant.statuses, isEmpty);

      // 添加状态
      controller.toggleStatus('c1', CombatantStatus.frightened);
      expect(combatant.statuses, contains(CombatantStatus.frightened));

      // 再次切换应移除
      controller.toggleStatus('c1', CombatantStatus.frightened);
      expect(combatant.statuses, isNot(contains(CombatantStatus.frightened)));
    });

    test('finishEncounter sets status to finished, finishedAt is set', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = CombatController(prefs: prefs);

      controller.createEncounter('Battle', [
        makeCombatant('c1', 'Alice', 15, 30),
      ]);

      expect(controller.currentEncounter, isNotNull);
      expect(controller.currentEncounter!.status, CombatStatus.ongoing);

      controller.finishEncounter();

      // currentEncounter 应为空
      expect(controller.currentEncounter, isNull);

      // 历史中应有 1 条记录
      expect(controller.history.length, 1);
      final finished = controller.history.first;
      expect(finished.status, CombatStatus.finished);
      expect(finished.finishedAt, isNotNull);
      expect(finished.name, 'Battle');
    });

    test('After save and reload, data is consistent', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = CombatController(prefs: prefs);

      controller.createEncounter('Persistent Battle', [
        makeCombatant('c1', 'Alice', 15, 30),
        makeCombatant('c2', 'Bob', 10, 20),
      ]);

      // 造成一些伤害
      controller.modifyHp('c1', -10);
      controller.modifyHp('c2', -5);

      // 创建新控制器实例（模拟重启）
      final restored = CombatController(prefs: prefs);

      expect(restored.currentEncounter, isNotNull);
      expect(restored.currentEncounter!.name, 'Persistent Battle');
      expect(restored.currentEncounter!.combatants.length, 2);
      expect(restored.currentEncounter!.combatants[0].currentHp, 20);
      expect(restored.currentEncounter!.combatants[0].damageTaken, 10);
      expect(restored.currentEncounter!.combatants[1].currentHp, 15);
      expect(restored.currentEncounter!.combatants[1].damageTaken, 5);
    });

    test('History persists after finishEncounter and reload', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = CombatController(prefs: prefs);

      controller.createEncounter('Battle 1', [
        makeCombatant('c1', 'Alice', 15, 30),
      ]);
      controller.finishEncounter();

      expect(controller.currentEncounter, isNull);
      expect(controller.history.length, 1);

      // 重新加载
      final restored = CombatController(prefs: prefs);
      expect(restored.currentEncounter, isNull);
      expect(restored.history.length, 1);
      expect(restored.history.first.name, 'Battle 1');
      expect(restored.history.first.status, CombatStatus.finished);
    });

    test('addCombatant and removeCombatant work correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = CombatController(prefs: prefs);

      controller.createEncounter('Battle', [
        makeCombatant('c1', 'Alice', 15, 30),
      ]);
      expect(controller.currentEncounter!.combatants.length, 1);

      // 添加新战斗者
      controller.addCombatant(makeCombatant('c2', 'Bob', 20, 25));
      expect(controller.currentEncounter!.combatants.length, 2);
      // Bob (dex 20) 应排在 Alice (dex 15) 前面
      expect(controller.currentEncounter!.combatants[0].name, 'Bob');

      // 移除 Bob
      controller.removeCombatant('c2');
      expect(controller.currentEncounter!.combatants.length, 1);
      expect(controller.currentEncounter!.combatants[0].name, 'Alice');
    });
  });
}
