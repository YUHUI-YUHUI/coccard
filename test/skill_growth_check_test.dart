import 'package:flutter_test/flutter_test.dart';
import 'package:coc_character/app/data/skill_check_record.dart';

void main() {
  group('SkillGrowthCheck.evaluate 纯函数', () {
    test('roll 等于 skillValue 时不成长', () {
      final r = SkillGrowthCheck.evaluate(
        skillName: '侦查',
        skillValue: 50,
        roll: 50,
        dieRoll: 5,
      );
      expect(r.grown, false);
      expect(r.increase, 0);
      expect(r.newSkillValue, 50);
    });

    test('roll 小于 skillValue 时不成长', () {
      final r = SkillGrowthCheck.evaluate(
        skillName: '侦查',
        skillValue: 50,
        roll: 30,
        dieRoll: 7,
      );
      expect(r.grown, false);
      expect(r.increase, 0);
      expect(r.newSkillValue, 50);
    });

    test('roll 大于 skillValue 时成长 +dieRoll', () {
      final r = SkillGrowthCheck.evaluate(
        skillName: '侦查',
        skillValue: 50,
        roll: 73,
        dieRoll: 4,
      );
      expect(r.grown, true);
      expect(r.increase, 4);
      expect(r.newSkillValue, 54);
    });

    test('roll=100 必定大于任何 skillValue（除 100 之外）', () {
      final r = SkillGrowthCheck.evaluate(
        skillName: '侦查',
        skillValue: 99,
        roll: 100,
        dieRoll: 10,
      );
      expect(r.grown, true);
      expect(r.increase, 10);
      expect(r.newSkillValue, 109);
    });

    test('dieRoll 范围 1..10 边界值均生效', () {
      final r1 = SkillGrowthCheck.evaluate(
        skillName: '侦查',
        skillValue: 30,
        roll: 31,
        dieRoll: 1,
      );
      expect(r1.increase, 1);
      expect(r1.newSkillValue, 31);

      final r10 = SkillGrowthCheck.evaluate(
        skillName: '侦查',
        skillValue: 30,
        roll: 31,
        dieRoll: 10,
      );
      expect(r10.increase, 10);
      expect(r10.newSkillValue, 40);
    });

    test('checkedAt 缺省时使用 DateTime.now', () {
      final before = DateTime.now();
      final r = SkillGrowthCheck.evaluate(
        skillName: '侦查',
        skillValue: 50,
        roll: 80,
        dieRoll: 3,
      );
      final after = DateTime.now();
      expect(r.checkedAt.isAfter(before.subtract(const Duration(seconds: 1))),
          true);
      expect(
          r.checkedAt.isBefore(after.add(const Duration(seconds: 1))), true);
    });

    test('checkedAt 显式传入时使用该值', () {
      final fixed = DateTime(2026, 6, 10, 22, 30);
      final r = SkillGrowthCheck.evaluate(
        skillName: '侦查',
        skillValue: 50,
        roll: 80,
        dieRoll: 3,
        checkedAt: fixed,
      );
      expect(r.checkedAt, fixed);
    });

    test('assert 校验 roll 越界', () {
      expect(
        () => SkillGrowthCheck.evaluate(
          skillName: '侦查',
          skillValue: 50,
          roll: 0,
          dieRoll: 5,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => SkillGrowthCheck.evaluate(
          skillName: '侦查',
          skillValue: 50,
          roll: 101,
          dieRoll: 5,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('assert 校验 dieRoll 越界', () {
      expect(
        () => SkillGrowthCheck.evaluate(
          skillName: '侦查',
          skillValue: 50,
          roll: 50,
          dieRoll: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => SkillGrowthCheck.evaluate(
          skillName: '侦查',
          skillValue: 50,
          roll: 50,
          dieRoll: 11,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
