import 'dart:math';

/// 大成功判定模式。
enum CriticalRuleMode {
  /// COC7 默认：roll == 1。
  oneOnly,

  /// 村规：roll <= [CheckRuleProfile.criticalMax]。
  fixedRange,
}

/// 大失败判定模式。
enum FumbleRuleMode {
  /// COC7 默认：目标值 < 50 时 96-100，>= 50 时只有 100。
  coc7,

  /// 村规：roll >= [CheckRuleProfile.fumbleMin]。
  fixedRange,
}

/// D100 检定规则档案。
class CheckRuleProfile {
  /// 规则标识。预置值：
  /// - `coc7`：官方默认。
  /// - `village_common`：常用村规（大成功 1-5、大失败 96-100）。
  /// - `custom`：用户自定义。
  final String id;
  final String name;
  final CriticalRuleMode criticalMode;

  /// fixedRange 下大成功的上界，闭区间。
  final int criticalMax;
  final FumbleRuleMode fumbleMode;

  /// fixedRange 下大失败的下界，闭区间。
  final int fumbleMin;
  final bool allowSpendLuck;

  const CheckRuleProfile({
    required this.id,
    required this.name,
    required this.criticalMode,
    required this.criticalMax,
    required this.fumbleMode,
    required this.fumbleMin,
    required this.allowSpendLuck,
  });

  CheckRuleProfile copyWith({
    String? id,
    String? name,
    CriticalRuleMode? criticalMode,
    int? criticalMax,
    FumbleRuleMode? fumbleMode,
    int? fumbleMin,
    bool? allowSpendLuck,
  }) {
    return CheckRuleProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      criticalMode: criticalMode ?? this.criticalMode,
      criticalMax: criticalMax ?? this.criticalMax,
      fumbleMode: fumbleMode ?? this.fumbleMode,
      fumbleMin: fumbleMin ?? this.fumbleMin,
      allowSpendLuck: allowSpendLuck ?? this.allowSpendLuck,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'criticalMode': criticalMode.name,
        'criticalMax': criticalMax,
        'fumbleMode': fumbleMode.name,
        'fumbleMin': fumbleMin,
        'allowSpendLuck': allowSpendLuck,
      };

  factory CheckRuleProfile.fromJson(Map<String, dynamic> json) {
    return CheckRuleProfile(
      id: json['id'] as String? ?? 'coc7',
      name: json['name'] as String? ?? 'COC7 默认',
      criticalMode: CriticalRuleMode.values.firstWhere(
        (m) => m.name == json['criticalMode'],
        orElse: () => CriticalRuleMode.oneOnly,
      ),
      criticalMax: json['criticalMax'] as int? ?? 1,
      fumbleMode: FumbleRuleMode.values.firstWhere(
        (m) => m.name == json['fumbleMode'],
        orElse: () => FumbleRuleMode.coc7,
      ),
      fumbleMin: json['fumbleMin'] as int? ?? 96,
      allowSpendLuck: json['allowSpendLuck'] as bool? ?? true,
    );
  }

  static const CheckRuleProfile coc7Default = CheckRuleProfile(
    id: 'coc7',
    name: 'COC7 默认',
    criticalMode: CriticalRuleMode.oneOnly,
    criticalMax: 1,
    fumbleMode: FumbleRuleMode.coc7,
    fumbleMin: 96,
    allowSpendLuck: true,
  );

  static const CheckRuleProfile villageCommon = CheckRuleProfile(
    id: 'village_common',
    name: '常用村规（大成功 1-5、大失败 96-100）',
    criticalMode: CriticalRuleMode.fixedRange,
    criticalMax: 5,
    fumbleMode: FumbleRuleMode.fixedRange,
    fumbleMin: 96,
    allowSpendLuck: true,
  );

  static const List<CheckRuleProfile> presets = [
    coc7Default,
    villageCommon,
  ];
}

/// 检定结果等级。
enum SkillCheckLevel { critical, extreme, hard, regular, failure, fumble }

extension SkillCheckLevelLabel on SkillCheckLevel {
  String get label {
    switch (this) {
      case SkillCheckLevel.critical:
        return '大成功';
      case SkillCheckLevel.extreme:
        return '极难成功';
      case SkillCheckLevel.hard:
        return '困难成功';
      case SkillCheckLevel.regular:
        return '普通成功';
      case SkillCheckLevel.failure:
        return '失败';
      case SkillCheckLevel.fumble:
        return '大失败';
    }
  }

  bool get isSuccess =>
      this == SkillCheckLevel.critical ||
      this == SkillCheckLevel.extreme ||
      this == SkillCheckLevel.hard ||
      this == SkillCheckLevel.regular;
}

/// D100 检定结果。
class SkillCheckResult {
  final int roll;
  final int skillValue;
  final int hardValue;
  final int extremeValue;
  final SkillCheckLevel level;
  final String ruleProfileId;

  const SkillCheckResult({
    required this.roll,
    required this.skillValue,
    required this.hardValue,
    required this.extremeValue,
    required this.level,
    required this.ruleProfileId,
  });

  bool get isSuccess => level.isSuccess;
  bool get canUseLuck => level == SkillCheckLevel.failure;
  int get luckCost => roll - skillValue;
  String get resultText => level.label;
}

/// D100 检定判定服务。判定顺序：大失败 → 大成功 → 极难 → 困难 → 普通 → 失败。
class D100CheckEvaluator {
  const D100CheckEvaluator();

  SkillCheckResult evaluate({
    required int target,
    required int roll,
    required CheckRuleProfile rule,
  }) {
    final t = max(0, target);
    final hardValue = t ~/ 2;
    final extremeValue = t ~/ 5;

    final criticalMax = _resolveCriticalMax(rule);
    final fumbleMin = _resolveFumbleMin(rule, t);
    final safeFumbleMin = max(fumbleMin, criticalMax + 1);

    late final SkillCheckLevel level;
    if (roll >= safeFumbleMin) {
      level = SkillCheckLevel.fumble;
    } else if (roll <= criticalMax) {
      level = SkillCheckLevel.critical;
    } else if (roll <= extremeValue) {
      level = SkillCheckLevel.extreme;
    } else if (roll <= hardValue) {
      level = SkillCheckLevel.hard;
    } else if (roll <= t) {
      level = SkillCheckLevel.regular;
    } else {
      level = SkillCheckLevel.failure;
    }

    return SkillCheckResult(
      roll: roll,
      skillValue: t,
      hardValue: hardValue,
      extremeValue: extremeValue,
      level: level,
      ruleProfileId: rule.id,
    );
  }

  int _resolveCriticalMax(CheckRuleProfile rule) {
    switch (rule.criticalMode) {
      case CriticalRuleMode.oneOnly:
        return 1;
      case CriticalRuleMode.fixedRange:
        return rule.criticalMax.clamp(1, 99);
    }
  }

  int _resolveFumbleMin(CheckRuleProfile rule, int target) {
    switch (rule.fumbleMode) {
      case FumbleRuleMode.coc7:
        return target < 50 ? 96 : 100;
      case FumbleRuleMode.fixedRange:
        return rule.fumbleMin.clamp(2, 100);
    }
  }
}
