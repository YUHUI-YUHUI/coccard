import 'dart:math';

import 'coc_data.dart';
import 'insanity_episode.dart';
import 'sanity_expression.dart';

/// SAN 损失触发临时疯狂的判定服务。
///
/// COC7 规则：
/// 1. 单次损失 ≥ [intCheckThreshold]（默认 5）需要进行 INT 检定；
/// 2. 检定成功（roll ≤ int）→ 陷入临时疯狂，掷 1D10 选即时症状 + 1D10 轮数；
/// 3. 检定失败 → 大脑屏蔽冲击，不陷入疯狂，但仍记录 SAN 损失；
/// 4. 单次损失 < 阈值 → 不需要 INT 检定，安静扣 SAN。
class InsanityService {
  /// 单次 SAN 损失多少以上需要 INT 检定。COC7 默认 5。
  final int intCheckThreshold;

  const InsanityService({
    this.intCheckThreshold = 5,
  });

  /// 决定本次 SAN 损失是否需要进入 INT 检定流程。
  bool shouldRunIntCheck(int loss) => loss >= intCheckThreshold;

  /// 执行 INT 检定。返回值包含投出值、目标值、是否成功。
  ///
  /// COC7 检定：掷 1D100，结果 ≤ INT 视为成功。
  IntCheckResult runIntCheck({required int intValue, required int roll}) {
    assert(roll >= 1 && roll <= 100, 'roll must be in 1..100');
    final success = roll <= intValue;
    return IntCheckResult(
      roll: roll,
      target: intValue,
      success: success,
    );
  }

  /// 在 INT 检定成功（陷入疯狂）后，随机选症状与持续轮数。
  InsanityEpisode pickTemporaryEpisode({
    required String id,
    required int sanityLoss,
    required IntCheckResult? intCheck,
    required int symptomRoll,
    required int durationRoll,
    required Random rng,
    DateTime? createdAt,
  }) {
    assert(symptomRoll >= 1 && symptomRoll <= 10, 'symptomRoll 必须是 1..10');
    assert(durationRoll >= 1 && durationRoll <= 10, 'durationRoll 必须是 1..10');
    final item = INSANITY_TMP[symptomRoll - 1];
    return InsanityEpisode(
      id: id,
      type: 'temporary',
      symptomRoll: symptomRoll,
      durationRoll: durationRoll,
      durationUnit: '轮',
      symptomText: item.text,
      sanityLoss: sanityLoss,
      intCheckRoll: intCheck?.roll,
      intCheckTarget: intCheck?.target,
      intCheckSuccess: intCheck?.success,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// 一步到位的便利方法：解析表达式、投骰、扣减 SAN、执行 INT 检定、
  /// 抽取症状。返回 [ApplySanityLossOutcome] 包含完整结果。
  ///
  /// 不负责写盘与 notify，调用方负责保存到 [Character]。
  ApplySanityLossOutcome apply({
    required String expression,
    required int currentSanity,
    required int maxSanity,
    required int intValue,
    required Random rng,
    DateTime? now,
  }) {
    final parsed = SanityExpression.parse(expression);
    if (parsed == null) {
      return ApplySanityLossOutcome.invalidExpression(expression);
    }

    final roll = parsed.roll(rng);
    final before = currentSanity;
    final after = (currentSanity - roll.total).clamp(0, maxSanity);
    // 实际 SAN 损失取"理论损失"与"剩余可扣"之间的较小者，
    // 避免出现"理论上扣 8 但只剩 3，结果日志却记 8"的歧义。
    final actualLoss = before - after;

    final shouldCheck = shouldRunIntCheck(actualLoss);
    IntCheckResult? intCheck;
    InsanityEpisode? episode;
    if (shouldCheck) {
      final intRoll = rng.nextInt(100) + 1;
      intCheck = runIntCheck(intValue: intValue, roll: intRoll);
      if (intCheck.success) {
        final symptomRoll = rng.nextInt(10) + 1;
        final durationRoll = rng.nextInt(10) + 1;
        episode = pickTemporaryEpisode(
          id: 'ep_${now?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}',
          sanityLoss: actualLoss,
          intCheck: intCheck,
          symptomRoll: symptomRoll,
          durationRoll: durationRoll,
          rng: rng,
          createdAt: now,
        );
      }
    }

    return ApplySanityLossOutcome.success(
      loss: actualLoss,
      rollDetail: roll.detail,
      sanityBefore: before,
      sanityAfter: after,
      intCheck: intCheck,
      episode: episode,
    );
  }
}

class IntCheckResult {
  final int roll;
  final int target;
  final bool success;
  const IntCheckResult({
    required this.roll,
    required this.target,
    required this.success,
  });
}

class ApplySanityLossOutcome {
  final bool isValid;
  final String? invalidExpression;

  final int loss;
  final String rollDetail;
  final int sanityBefore;
  final int sanityAfter;
  final IntCheckResult? intCheck;
  final InsanityEpisode? episode;

  const ApplySanityLossOutcome._({
    required this.isValid,
    this.invalidExpression,
    this.loss = 0,
    this.rollDetail = '',
    this.sanityBefore = 0,
    this.sanityAfter = 0,
    this.intCheck,
    this.episode,
  });

  factory ApplySanityLossOutcome.invalidExpression(String expr) =>
      ApplySanityLossOutcome._(isValid: false, invalidExpression: expr);

  factory ApplySanityLossOutcome.success({
    required int loss,
    required String rollDetail,
    required int sanityBefore,
    required int sanityAfter,
    IntCheckResult? intCheck,
    InsanityEpisode? episode,
  }) =>
      ApplySanityLossOutcome._(
        isValid: true,
        loss: loss,
        rollDetail: rollDetail,
        sanityBefore: sanityBefore,
        sanityAfter: sanityAfter,
        intCheck: intCheck,
        episode: episode,
      );

  bool get triggeredInsanity => episode != null;
  bool get ranIntCheck => intCheck != null;
}
