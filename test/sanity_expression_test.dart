import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:coc_character/app/data/sanity_expression.dart';

void main() {
  group('SanityExpression.parse 解析', () {
    test('纯数字解析为固定值', () {
      final e = SanityExpression.parse('5');
      expect(e, isNotNull);
      expect(e!.count, 0);
      expect(e.die, 0);
      expect(e.modifier, 5);
    });

    test('1d6 解析正确', () {
      final e = SanityExpression.parse('1d6');
      expect(e, isNotNull);
      expect(e!.count, 1);
      expect(e.die, 6);
      expect(e.modifier, 0);
    });

    test('2d6+1 解析正确', () {
      final e = SanityExpression.parse('2d6+1');
      expect(e, isNotNull);
      expect(e!.count, 2);
      expect(e.die, 6);
      expect(e.modifier, 1);
    });

    test('1d6-2 解析正确', () {
      final e = SanityExpression.parse('1d6-2');
      expect(e, isNotNull);
      expect(e!.count, 1);
      expect(e.die, 6);
      expect(e.modifier, -2);
    });

    test('大小写、空格不敏感', () {
      final e = SanityExpression.parse(' 1D10 + 3 ');
      expect(e, isNotNull);
      expect(e!.count, 1);
      expect(e.die, 10);
      expect(e.modifier, 3);
    });

    test('非法骰面返回 null', () {
      expect(SanityExpression.parse('1d1'), isNull);
      expect(SanityExpression.parse('1d101'), isNull);
    });

    test('非法骰数返回 null', () {
      expect(SanityExpression.parse('0d6'), isNull);
      expect(SanityExpression.parse('21d6'), isNull);
    });

    test('非法输入返回 null', () {
      expect(SanityExpression.parse(''), isNull);
      expect(SanityExpression.parse('abc'), isNull);
      expect(SanityExpression.parse('1d6+'), isNull);
      expect(SanityExpression.parse('-5'), isNull);
    });
  });

  group('SanityExpression.roll 投骰（确定性 Random）', () {
    test('纯数字表达式：直接返回数字', () {
      final e = SanityExpression.parse('5')!;
      final r = e.roll(_StubRandom(0));
      expect(r.total, 5);
      expect(r.detail, '5');
    });

    test('1d6 投出 [3]', () {
      final e = SanityExpression.parse('1d6')!;
      final r = e.roll(_StubRandom(2)); // nextInt(6) -> 2 → +1 = 3
      expect(r.total, 3);
      expect(r.detail, '1d6=3=3');
    });

    test('2d6+1 投出 [3,5]+1=9', () {
      final e = SanityExpression.parse('2d6+1')!;
      final r = e.roll(_StubRandom.sequence([2, 4])); // 3, 5
      expect(r.total, 9);
      expect(r.detail, '2d6=3+5+1=9');
    });

    test('1d6-10 clamp 到 0', () {
      final e = SanityExpression.parse('1d6-10')!;
      final r = e.roll(_StubRandom(0));
      expect(r.total, 0);
    });
  });
}

/// 测试用确定性 Random：nextInt(0) 返回 0；nextInt(max) 走 sequence 注入或
/// 单一 next 值。继承 Random 以满足类型约束。
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
