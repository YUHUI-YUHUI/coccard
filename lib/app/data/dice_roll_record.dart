/// 单次本地骰点记录。仅记录在本机，不会上传或同步给其他玩家。
class DiceRollRecord {
  /// 骰面类型，例如 'D100' 或 '3D6'。
  final String diceType;

  /// 结果数值。
  final int value;

  /// 投骰时间。
  final DateTime createdAt;

  /// 可选备注（例如 "侦查 70 困难成功"）。
  final String? note;

  const DiceRollRecord({
    required this.diceType,
    required this.value,
    required this.createdAt,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'diceType': diceType,
        'value': value,
        'createdAt': createdAt.toIso8601String(),
        if (note != null) 'note': note,
      };

  factory DiceRollRecord.fromJson(Map<String, dynamic> json) {
    return DiceRollRecord(
      diceType: json['diceType'] as String? ?? 'D100',
      value: json['value'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      note: json['note'] as String?,
    );
  }
}