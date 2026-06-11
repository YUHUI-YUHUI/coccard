/// 临时/长期疯狂发作记录。
///
/// 触发流程（COC7）：
/// 1. 单次 SAN 损失 ≥ [intCheckThreshold] 时进行 INT 检定。
/// 2. INT 检定成功 → 陷入临时疯狂（持续 1D10 轮）。
/// 3. INT 检定失败 → 大脑屏蔽冲击，但仍记录 SAN 损失（不进入疯狂状态）。
class InsanityEpisode {
  final String id;

  /// `temporary` 或 `indefinite`，目前 P2 阶段只使用 `temporary`。
  final String type;

  /// 1..10，对应 `INSANITY_TMP` 列表中的下标。
  final int symptomRoll;

  /// 1..10，对应 1D10 轮/小时。
  final int durationRoll;

  /// `轮` 或 `小时`。
  final String durationUnit;

  /// 症状文本（直接存储避免再次查表，方便导出与展示）。
  final String symptomText;

  /// 触发的本次 SAN 损失。
  final int sanityLoss;

  /// INT 检定投出值（1..100）。
  final int? intCheckRoll;

  /// 当时的 INT 属性值。
  final int? intCheckTarget;

  /// INT 检定是否成功（成功则陷入疯狂，失败则大脑屏蔽）。
  final bool? intCheckSuccess;

  final DateTime createdAt;

  const InsanityEpisode({
    required this.id,
    required this.type,
    required this.symptomRoll,
    required this.durationRoll,
    required this.durationUnit,
    required this.symptomText,
    required this.sanityLoss,
    required this.createdAt,
    this.intCheckRoll,
    this.intCheckTarget,
    this.intCheckSuccess,
  });

  bool get triggeredInsanity =>
      intCheckSuccess == true && type == 'temporary';

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'symptomRoll': symptomRoll,
        'durationRoll': durationRoll,
        'durationUnit': durationUnit,
        'symptomText': symptomText,
        'sanityLoss': sanityLoss,
        'intCheckRoll': intCheckRoll,
        'intCheckTarget': intCheckTarget,
        'intCheckSuccess': intCheckSuccess,
        'createdAt': createdAt.toIso8601String(),
      };

  factory InsanityEpisode.fromJson(Map<String, dynamic> json) {
    return InsanityEpisode(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'temporary',
      symptomRoll: json['symptomRoll'] as int? ?? 0,
      durationRoll: json['durationRoll'] as int? ?? 0,
      durationUnit: json['durationUnit'] as String? ?? '轮',
      symptomText: json['symptomText'] as String? ?? '',
      sanityLoss: json['sanityLoss'] as int? ?? 0,
      intCheckRoll: json['intCheckRoll'] as int?,
      intCheckTarget: json['intCheckTarget'] as int?,
      intCheckSuccess: json['intCheckSuccess'] as bool?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
