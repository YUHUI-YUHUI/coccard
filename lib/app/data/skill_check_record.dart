import 'check_rule.dart';

/// 单次技能检定的日志条目。
class SkillCheckRecord {
  final String id;
  final String skillName;
  final int skillValue;
  final int roll;
  final SkillCheckLevel level;

  /// 最终是否成功。花费幸运补正后会被改写为 true。
  final bool finalSuccess;
  final bool luckSpent;
  final int? luckCost;
  final String ruleProfileId;
  final DateTime createdAt;

  const SkillCheckRecord({
    required this.id,
    required this.skillName,
    required this.skillValue,
    required this.roll,
    required this.level,
    required this.finalSuccess,
    required this.ruleProfileId,
    required this.createdAt,
    this.luckSpent = false,
    this.luckCost,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'skillName': skillName,
        'skillValue': skillValue,
        'roll': roll,
        'level': level.name,
        'finalSuccess': finalSuccess,
        'luckSpent': luckSpent,
        'luckCost': luckCost,
        'ruleProfileId': ruleProfileId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SkillCheckRecord.fromJson(Map<String, dynamic> json) {
    return SkillCheckRecord(
      id: json['id'] as String? ?? '',
      skillName: json['skillName'] as String? ?? '',
      skillValue: json['skillValue'] as int? ?? 0,
      roll: json['roll'] as int? ?? 0,
      level: SkillCheckLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => SkillCheckLevel.failure,
      ),
      finalSuccess: json['finalSuccess'] as bool? ?? false,
      luckSpent: json['luckSpent'] as bool? ?? false,
      luckCost: json['luckCost'] as int?,
      ruleProfileId: json['ruleProfileId'] as String? ?? 'coc7',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// 某个技能的成长状态聚合。
class SkillGrowthState {
  final String skillName;
  int successCount;
  int failureCount;
  bool growthMarked;
  DateTime? lastCheckedAt;
  DateTime? lastGrowthAt;

  SkillGrowthState({
    required this.skillName,
    this.successCount = 0,
    this.failureCount = 0,
    this.growthMarked = false,
    this.lastCheckedAt,
    this.lastGrowthAt,
  });

  Map<String, dynamic> toJson() => {
        'skillName': skillName,
        'successCount': successCount,
        'failureCount': failureCount,
        'growthMarked': growthMarked,
        'lastCheckedAt': lastCheckedAt?.toIso8601String(),
        'lastGrowthAt': lastGrowthAt?.toIso8601String(),
      };

  factory SkillGrowthState.fromJson(Map<String, dynamic> json) {
    return SkillGrowthState(
      skillName: json['skillName'] as String? ?? '',
      successCount: json['successCount'] as int? ?? 0,
      failureCount: json['failureCount'] as int? ?? 0,
      growthMarked: json['growthMarked'] as bool? ?? false,
      lastCheckedAt: DateTime.tryParse(json['lastCheckedAt'] as String? ?? ''),
      lastGrowthAt: DateTime.tryParse(json['lastGrowthAt'] as String? ?? ''),
    );
  }
}

/// 幕间技能成长检定结果。
///
/// COC7 规则：成功检定过的技能在幕间掷 1D100，结果大于当前技能值即成长 +1D10。
class SkillGrowthCheck {
  final String skillName;
  final int skillValue;
  final int roll;

  /// 实际增加的技能值（0 表示未成长）。
  final int increase;

  /// 成长后的技能值（= skillValue + increase）。
  final int newSkillValue;
  final DateTime checkedAt;

  const SkillGrowthCheck({
    required this.skillName,
    required this.skillValue,
    required this.roll,
    required this.increase,
    required this.newSkillValue,
    required this.checkedAt,
  });

  bool get grown => increase > 0;

  /// 纯函数：掷 1D100 决定是否成长。
  ///
  /// - [roll] 必须在 1..100 范围内（调用方负责边界）。
  /// - 成长条件：roll > skillValue 且 roll <= 100。
  /// - 成功时 increase = 1D10（由 [dieRoll] 注入，便于测试）。
  static SkillGrowthCheck evaluate({
    required String skillName,
    required int skillValue,
    required int roll,
    required int dieRoll,
    DateTime? checkedAt,
  }) {
    assert(roll >= 1 && roll <= 100, 'roll must be in 1..100');
    assert(dieRoll >= 1 && dieRoll <= 10, 'dieRoll must be in 1..10');
    final grown = roll > skillValue;
    final increase = grown ? dieRoll : 0;
    return SkillGrowthCheck(
      skillName: skillName,
      skillValue: skillValue,
      roll: roll,
      increase: increase,
      newSkillValue: skillValue + increase,
      checkedAt: checkedAt ?? DateTime.now(),
    );
  }
}
