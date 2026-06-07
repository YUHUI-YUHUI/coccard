import 'package:flutter_test/flutter_test.dart';
import 'package:coc_character/app/data/check_rule.dart';

void main() {
  const evaluator = D100CheckEvaluator();
  const coc7 = CheckRuleProfile.coc7Default;
  const village = CheckRuleProfile.villageCommon;

  SkillCheckLevel levelOf(int target, int roll, CheckRuleProfile rule) =>
      evaluator.evaluate(target: target, roll: roll, rule: rule).level;

  group('COC7 默认规则', () {
    test('目标 40，1 为大成功', () {
      expect(levelOf(40, 1, coc7), SkillCheckLevel.critical);
    });

    test('目标 40，roll<=8 为极难（40/5=8）', () {
      expect(levelOf(40, 8, coc7), SkillCheckLevel.extreme);
      expect(levelOf(40, 9, coc7), SkillCheckLevel.hard);
    });

    test('目标 40，roll<=20 为困难（40/2=20）', () {
      expect(levelOf(40, 20, coc7), SkillCheckLevel.hard);
      expect(levelOf(40, 21, coc7), SkillCheckLevel.regular);
    });

    test('目标 40，roll=40 为普通成功，41 为失败', () {
      expect(levelOf(40, 40, coc7), SkillCheckLevel.regular);
      expect(levelOf(40, 41, coc7), SkillCheckLevel.failure);
    });

    test('目标 40，96-100 均为大失败', () {
      for (final r in [96, 97, 98, 99, 100]) {
        expect(levelOf(40, r, coc7), SkillCheckLevel.fumble, reason: 'roll=$r');
      }
    });

    test('目标 50，96 为失败，100 为大失败', () {
      expect(levelOf(50, 96, coc7), SkillCheckLevel.failure);
      expect(levelOf(50, 99, coc7), SkillCheckLevel.failure);
      expect(levelOf(50, 100, coc7), SkillCheckLevel.fumble);
    });

    test('目标 80，1 为大成功，16 为极难，40 为困难，80 为普通', () {
      expect(levelOf(80, 1, coc7), SkillCheckLevel.critical);
      expect(levelOf(80, 16, coc7), SkillCheckLevel.extreme);
      expect(levelOf(80, 40, coc7), SkillCheckLevel.hard);
      expect(levelOf(80, 80, coc7), SkillCheckLevel.regular);
      expect(levelOf(80, 81, coc7), SkillCheckLevel.failure);
    });

    test('目标 80，100 才是大失败', () {
      expect(levelOf(80, 96, coc7), SkillCheckLevel.failure);
      expect(levelOf(80, 100, coc7), SkillCheckLevel.fumble);
    });

    test('目标 0 时所有非大失败 roll 都失败', () {
      expect(levelOf(0, 1, coc7), SkillCheckLevel.critical);
      expect(levelOf(0, 50, coc7), SkillCheckLevel.failure);
      expect(levelOf(0, 96, coc7), SkillCheckLevel.fumble);
    });
  });

  group('村规：大成功 1-5、大失败 96-100', () {
    test('1-5 全部为大成功', () {
      for (final r in [1, 2, 3, 4, 5]) {
        expect(levelOf(80, r, village), SkillCheckLevel.critical, reason: 'roll=$r');
      }
    });

    test('目标 50，96-100 均为大失败', () {
      for (final r in [96, 97, 100]) {
        expect(levelOf(50, r, village), SkillCheckLevel.fumble, reason: 'roll=$r');
      }
    });

    test('目标 40，96-100 均为大失败', () {
      for (final r in [96, 97, 100]) {
        expect(levelOf(40, r, village), SkillCheckLevel.fumble, reason: 'roll=$r');
      }
    });

    test('目标 80，roll=6（村规大成功阈值之外）落在极难范围（80/5=16）', () {
      expect(levelOf(80, 6, village), SkillCheckLevel.extreme);
    });

    test('目标 80，roll=20 在困难范围（80/2=40）', () {
      expect(levelOf(80, 20, village), SkillCheckLevel.hard);
    });

    test('目标 40，roll=21 在普通成功范围（>困难阈值 20 且 <=40）', () {
      expect(levelOf(40, 21, village), SkillCheckLevel.regular);
    });

    test('村规下 95 仍是失败（不到 96）', () {
      expect(levelOf(50, 95, village), SkillCheckLevel.failure);
    });
  });

  group('结果元数据', () {
    test('hardValue / extremeValue 按整除计算', () {
      final r = evaluator.evaluate(target: 75, roll: 50, rule: coc7);
      expect(r.skillValue, 75);
      expect(r.hardValue, 37);
      expect(r.extremeValue, 15);
      expect(r.ruleProfileId, 'coc7');
    });

    test('luckCost = roll - skillValue', () {
      final r = evaluator.evaluate(target: 50, roll: 65, rule: coc7);
      expect(r.luckCost, 15);
      expect(r.canUseLuck, isTrue);
    });

    test('大失败不可用幸运补正', () {
      final r = evaluator.evaluate(target: 50, roll: 100, rule: coc7);
      expect(r.canUseLuck, isFalse);
    });

    test('负目标值被夹到 0', () {
      final r = evaluator.evaluate(target: -5, roll: 50, rule: coc7);
      expect(r.skillValue, 0);
      expect(r.level, SkillCheckLevel.failure);
    });
  });

  group('CheckRuleProfile JSON 兼容', () {
    test('toJson/fromJson 保留全部字段', () {
      final json = CheckRuleProfile.villageCommon.toJson();
      final restored = CheckRuleProfile.fromJson(json);
      expect(restored.id, 'village_common');
      expect(restored.criticalMode, CriticalRuleMode.fixedRange);
      expect(restored.criticalMax, 5);
      expect(restored.fumbleMode, FumbleRuleMode.fixedRange);
      expect(restored.fumbleMin, 96);
    });

    test('缺字段回退为 COC7 默认', () {
      final restored = CheckRuleProfile.fromJson({});
      expect(restored.id, 'coc7');
      expect(restored.criticalMode, CriticalRuleMode.oneOnly);
      expect(restored.fumbleMode, FumbleRuleMode.coc7);
    });
  });
}
