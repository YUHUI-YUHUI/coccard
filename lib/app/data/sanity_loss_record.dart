/// 单次 SAN 损失日志条目。
///
/// 记录原始表达式（例如 "1d6+1"）、投骰明细、损失前后理智值，
/// 以及本次损失是否触发了疯狂检定（不保存检定细节，检定细节在
/// [InsanityEpisode] 中）。
class SanityLossRecord {
  final String id;

  /// 玩家输入的原始表达式，例如 `1d6`、`2d6+1`、`1d10-2`、`5`。
  final String expression;

  /// 实际投出的伤害骰明细，格式如 `1d6+1=[3]+1=4`。
  final String rollDetail;

  /// 本次最终损失（已 clamp 到 ≥ 0）。
  final int amount;

  /// 损失前的 SAN 值。
  final int sanityBefore;

  /// 损失后的 SAN 值。
  final int sanityAfter;

  /// 损失后是否触发了 INT 检定（仅当 [amount] ≥ 触发阈值）。
  final bool intCheckTriggered;

  final DateTime createdAt;

  const SanityLossRecord({
    required this.id,
    required this.expression,
    required this.rollDetail,
    required this.amount,
    required this.sanityBefore,
    required this.sanityAfter,
    required this.intCheckTriggered,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'expression': expression,
        'rollDetail': rollDetail,
        'amount': amount,
        'sanityBefore': sanityBefore,
        'sanityAfter': sanityAfter,
        'intCheckTriggered': intCheckTriggered,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SanityLossRecord.fromJson(Map<String, dynamic> json) {
    return SanityLossRecord(
      id: json['id'] as String? ?? '',
      expression: json['expression'] as String? ?? '',
      rollDetail: json['rollDetail'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      sanityBefore: json['sanityBefore'] as int? ?? 0,
      sanityAfter: json['sanityAfter'] as int? ?? 0,
      intCheckTriggered: json['intCheckTriggered'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
