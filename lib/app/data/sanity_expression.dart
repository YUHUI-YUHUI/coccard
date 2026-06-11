import 'dart:math';

/// 解析并投掷 SAN 损失表达式。
///
/// 支持的表达式形式（大小写不敏感、允许空白）：
///   - `5`              固定值
///   - `1d6`            一颗六面骰
///   - `2d6`            两颗六面骰
///   - `1d10+1`         一颗十面骰加 1
///   - `1d6-1`          一颗六面骰减 1
///   - `2d6+3`          两颗六面骰加 3
///
/// 骰面合法范围 2..100，加减项最终 clamp 到 ≥ 0，避免极端输入产生负损失。
class SanityExpression {
  final int count;
  final int die;
  final int modifier;

  const SanityExpression._({
    required this.count,
    required this.die,
    required this.modifier,
  });

  /// 解析失败返回 `null`。
  ///
  /// 输入支持：纯数字、`<count>d<die>`、`<count>d<die>+<mod>`、
  /// `<count>d<die>-<mod>`。骰子面数必须在 2..100 之间，数量 1..20。
  static SanityExpression? parse(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) return null;

    // 纯数字：固定损失
    final asInt = int.tryParse(trimmed);
    if (asInt != null) {
      if (asInt < 0) return null;
      return SanityExpression._(count: 0, die: 0, modifier: asInt);
    }

    // dice 表达式
    final re = RegExp(
      r'^\s*(\d+)\s*d\s*(\d+)\s*([+-]\s*\d+)?\s*$',
    );
    final m = re.firstMatch(trimmed);
    if (m == null) return null;

    final count = int.parse(m.group(1)!);
    final die = int.parse(m.group(2)!);
    var modifier = 0;
    if (m.group(3) != null) {
      modifier = int.parse(m.group(3)!.replaceAll(' ', ''));
    }

    if (count < 1 || count > 20) return null;
    if (die < 2 || die > 100) return null;
    if (modifier < -100 || modifier > 100) return null;

    return SanityExpression._(
      count: count,
      die: die,
      modifier: modifier,
    );
  }

  /// 在解析成功后投掷；解析失败抛 [ArgumentError]。
  ///
  /// 返回 `RollResult` 包含骰面明细字符串与最终值。
  RollResult roll(Random rng) {
    assert(count > 0 || modifier > 0,
        'SanityExpression.roll 只能用于已解析的表达式');
    if (count == 0) {
      // 纯数字表达式，没有骰子要投
      return RollResult(
        detail: '$modifier',
        total: modifier < 0 ? 0 : modifier,
      );
    }
    final rolls = <int>[];
    var sum = 0;
    for (var i = 0; i < count; i++) {
      final v = rng.nextInt(die) + 1;
      rolls.add(v);
      sum += v;
    }
    final total = sum + modifier;
    final clamped = total < 0 ? 0 : total;

    final rollList = rolls.join('+');
    final modPart = modifier == 0
        ? ''
        : (modifier > 0 ? '+$modifier' : '$modifier');
    final detail = modPart.isEmpty
        ? '${count}d$die=$rollList=$clamped'
        : '${count}d$die=$rollList$modPart=$clamped';
    return RollResult(detail: detail, total: clamped);
  }
}

class RollResult {
  final String detail;
  final int total;
  const RollResult({required this.detail, required this.total});
}
