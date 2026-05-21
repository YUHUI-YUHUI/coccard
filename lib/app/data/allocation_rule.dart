import 'dart:math';

enum AllocationMethod { destiny, pointBuy }

/// 属性分配规则。
/// - 天命 N：骰 N 组属性，玩家选其中一组。
/// - 购点 X：玩家在 X 总点数内自由分配 8 项。
/// - includeLuck=false（不含运）：运气单独由 3D6×5 投出，不参与上面机制。
class AllocationRule {
  final AllocationMethod method;
  final int destinyGroups;
  final int pointBuyTotal;
  final bool includeLuck;

  const AllocationRule({
    required this.method,
    this.destinyGroups = 3,
    this.pointBuyTotal = 480,
    this.includeLuck = false,
  });

  static const AllocationRule defaultRule = AllocationRule(
    method: AllocationMethod.pointBuy,
    pointBuyTotal: 480,
    includeLuck: false,
  );

  static const int perAttributeMin = 40;
  static const int perAttributeMax = 90;

  String get label {
    switch (method) {
      case AllocationMethod.destiny:
        return '天命$destinyGroups${includeLuck ? '（含运）' : '（不含运）'}';
      case AllocationMethod.pointBuy:
        return '$pointBuyTotal购点${includeLuck ? '含运' : '不含运'}';
    }
  }

  AllocationRule copyWith({
    AllocationMethod? method,
    int? destinyGroups,
    int? pointBuyTotal,
    bool? includeLuck,
  }) {
    return AllocationRule(
      method: method ?? this.method,
      destinyGroups: destinyGroups ?? this.destinyGroups,
      pointBuyTotal: pointBuyTotal ?? this.pointBuyTotal,
      includeLuck: includeLuck ?? this.includeLuck,
    );
  }

  /// 从玩家描述里解析规则。未匹配到则返回 null（由调用方退回默认规则）。
  static AllocationRule? parseFromDescription(String desc) {
    if (desc.isEmpty) return null;
    final text = desc.replaceAll(' ', '');

    // 天命 N
    final destiny = RegExp(r'天命\s*(\d+)').firstMatch(text);
    if (destiny != null) {
      final n = int.tryParse(destiny.group(1)!) ?? 3;
      final includeLuck = text.contains('含运') && !text.contains('不含运');
      return AllocationRule(
        method: AllocationMethod.destiny,
        destinyGroups: n.clamp(1, 10),
        includeLuck: includeLuck,
      );
    }

    // 购点 X（X购点 / 购点X / X点购点 等常见写法）
    final buyA = RegExp(r'(\d+)\s*购点').firstMatch(text);
    final buyB = RegExp(r'购点\s*[:：]?\s*(\d+)').firstMatch(text);
    final match = buyA ?? buyB;
    if (match != null) {
      final x = int.tryParse(match.group(1)!) ?? 480;
      final includeLuck = text.contains('含运') && !text.contains('不含运');
      return AllocationRule(
        method: AllocationMethod.pointBuy,
        pointBuyTotal: x.clamp(8 * perAttributeMin, 8 * perAttributeMax + (includeLuck ? perAttributeMax : 0)),
        includeLuck: includeLuck,
      );
    }
    return null;
  }
}

/// COC 7e 标准属性投骰公式。
class CocDice {
  CocDice._();

  static int _d6(Random r) => r.nextInt(6) + 1;

  /// 3D6×5：用于 STR / CON / DEX / APP / POW / Luck。范围 15–90，期望 52.5。
  static int roll3d6x5(Random r) => (_d6(r) + _d6(r) + _d6(r)) * 5;

  /// (2D6+6)×5：用于 SIZ / INT / EDU。范围 40–90，期望 65。
  static int roll2d6p6x5(Random r) => (_d6(r) + _d6(r) + 6) * 5;

  /// 投出一组完整属性（含/不含 luck）。键：str/con/siz/dex/app/int/pow/edu/luck。
  static Map<String, int> rollAttributeSet(
    Random r, {
    required bool includeLuck,
  }) {
    return {
      'str': roll3d6x5(r),
      'con': roll3d6x5(r),
      'siz': roll2d6p6x5(r),
      'dex': roll3d6x5(r),
      'app': roll3d6x5(r),
      'int': roll2d6p6x5(r),
      'pow': roll3d6x5(r),
      'edu': roll2d6p6x5(r),
      if (includeLuck) 'luck': roll3d6x5(r),
    };
  }

  /// 投运气（单独，3D6×5）。
  static int rollLuck(Random r) => roll3d6x5(r);
}
