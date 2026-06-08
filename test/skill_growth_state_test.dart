import 'package:flutter_test/flutter_test.dart';
import 'package:coc_character/app/data/skill_check_record.dart';

void main() {
  group('SkillGrowthState JSON 兼容', () {
    test('默认 toJson 字段齐全', () {
      final s = SkillGrowthState(skillName: '侦查');
      final json = s.toJson();
      expect(json['skillName'], '侦查');
      expect(json['successCount'], 0);
      expect(json['failureCount'], 0);
      expect(json['growthMarked'], false);
    });

    test('fromJson 缺字段使用默认值（旧数据兼容）', () {
      final s = SkillGrowthState.fromJson(<String, dynamic>{});
      expect(s.skillName, '');
      expect(s.successCount, 0);
      expect(s.failureCount, 0);
      expect(s.growthMarked, false);
      expect(s.lastCheckedAt, isNull);
      expect(s.lastGrowthAt, isNull);
    });

    test('完整 round-trip 保持字段', () {
      final now = DateTime(2026, 6, 8, 12, 30);
      final s = SkillGrowthState(
        skillName: '侦查',
        successCount: 3,
        failureCount: 1,
        growthMarked: true,
        lastCheckedAt: now,
        lastGrowthAt: now,
      );
      final restored = SkillGrowthState.fromJson(s.toJson());
      expect(restored.skillName, '侦查');
      expect(restored.successCount, 3);
      expect(restored.failureCount, 1);
      expect(restored.growthMarked, true);
      expect(restored.lastCheckedAt, now);
      expect(restored.lastGrowthAt, now);
    });
  });
}
