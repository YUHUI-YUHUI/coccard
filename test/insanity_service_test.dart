import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:coc_character/app/data/insanity_service.dart';

void main() {
  group('InsanityService.shouldRunIntCheck', () {
    test('默认阈值 5，损失 < 5 不需要 INT 检定', () {
      const svc = InsanityService();
      expect(svc.shouldRunIntCheck(0), false);
      expect(svc.shouldRunIntCheck(1), false);
      expect(svc.shouldRunIntCheck(4), false);
    });

    test('默认阈值 5，损失 >= 5 需要 INT 检定', () {
      const svc = InsanityService();
      expect(svc.shouldRunIntCheck(5), true);
      expect(svc.shouldRunIntCheck(10), true);
      expect(svc.shouldRunIntCheck(99), true);
    });

    test('自定义阈值生效', () {
      const svc = InsanityService(intCheckThreshold: 3);
      expect(svc.shouldRunIntCheck(2), false);
      expect(svc.shouldRunIntCheck(3), true);
    });
  });

  group('InsanityService.runIntCheck', () {
    test('roll 等于 int 视为成功', () {
      const svc = InsanityService();
      final r = svc.runIntCheck(intValue: 50, roll: 50);
      expect(r.success, true);
    });

    test('roll 小于 int 视为成功', () {
      const svc = InsanityService();
      final r = svc.runIntCheck(intValue: 60, roll: 30);
      expect(r.success, true);
    });

    test('roll 大于 int 视为失败', () {
      const svc = InsanityService();
      final r = svc.runIntCheck(intValue: 50, roll: 51);
      expect(r.success, false);
    });
  });

  group('InsanityService.apply 一站式流程', () {
    test('损失 < 阈值：安静扣 SAN，无 episode', () {
      const svc = InsanityService();
      final r = svc.apply(
        expression: '1d6', // 投出 3
        currentSanity: 50,
        maxSanity: 99,
        intValue: 60,
        rng: _StubRandom(2), // nextInt(6)=2 → 3
      );
      expect(r.isValid, true);
      expect(r.loss, 3);
      expect(r.sanityBefore, 50);
      expect(r.sanityAfter, 47);
      expect(r.ranIntCheck, false);
      expect(r.episode, isNull);
    });

    test('损失 >= 阈值 + INT 成功：触发临时疯狂，掷症状与轮数', () {
      const svc = InsanityService();
      // 投骰顺序（每次 nextInt 返回 N，实际骰值是 N+1）：
      //   nextInt(6) for 1d6 -> 5 → 骰值 6（损失 6，触发 INT）
      //   nextInt(100) for INT -> 40 → 投出 41（≤50 成功）
      //   nextInt(10) for symptom -> 2 → 症状 #3
      //   nextInt(10) for duration -> 6 → 7 轮
      final r = svc.apply(
        expression: '1d6',
        currentSanity: 60,
        maxSanity: 99,
        intValue: 50,
        rng: _StubRandom.sequence([5, 40, 2, 6]),
      );
      expect(r.isValid, true);
      expect(r.loss, 6);
      expect(r.ranIntCheck, true);
      expect(r.intCheck!.roll, 41);
      expect(r.intCheck!.success, true);
      expect(r.episode, isNotNull);
      expect(r.episode!.symptomRoll, 3);
      expect(r.episode!.durationRoll, 7);
      expect(r.episode!.durationUnit, '轮');
      expect(r.episode!.sanityLoss, 6);
      expect(r.episode!.triggeredInsanity, true);
    });

    test('损失 >= 阈值 + INT 失败：不触发疯狂', () {
      const svc = InsanityService();
      // 投骰顺序：1d6=6, INT roll=80 (失败)
      final r = svc.apply(
        expression: '1d6',
        currentSanity: 60,
        maxSanity: 99,
        intValue: 50,
        rng: _StubRandom.sequence([5, 80]),
      );
      expect(r.isValid, true);
      expect(r.loss, 6);
      expect(r.ranIntCheck, true);
      expect(r.intCheck!.success, false);
      expect(r.episode, isNull);
    });

    test('SAN 已为 0：实际损失 0，不触发 INT 检定', () {
      const svc = InsanityService();
      // 即便表达式是 1d10（=10），剩余可扣为 0，应 clamp。
      final r = svc.apply(
        expression: '1d10',
        currentSanity: 0,
        maxSanity: 99,
        intValue: 50,
        rng: _StubRandom(9), // 1d10=10
      );
      expect(r.loss, 0);
      expect(r.sanityAfter, 0);
      expect(r.ranIntCheck, false);
    });

    test('非法表达式：返回 invalidExpression', () {
      const svc = InsanityService();
      final r = svc.apply(
        expression: 'abc',
        currentSanity: 50,
        maxSanity: 99,
        intValue: 50,
        rng: _StubRandom(0),
      );
      expect(r.isValid, false);
      expect(r.invalidExpression, 'abc');
    });
  });
}

class _StubRandom implements Random {
  final int? next;
  final List<int>? sequence;
  int _seqIndex = 0;
  _StubRandom(this.next) : sequence = null;
  _StubRandom.sequence(this.sequence) : next = null;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.5;

  @override
  int nextInt(int max) {
    if (sequence != null) {
      return sequence![_seqIndex++ % sequence!.length];
    }
    return next ?? 0;
  }
}
