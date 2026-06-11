import 'package:flutter_test/flutter_test.dart';
import 'package:coc_character/app/data/character.dart';
import 'package:coc_character/app/data/check_rule.dart';
import 'package:coc_character/app/data/insanity_episode.dart';
import 'package:coc_character/app/data/sanity_loss_record.dart';
import 'package:coc_character/app/data/skill_check_record.dart';

void main() {
  group('Character JSON 兼容（新增 SAN/Insanity 字段）', () {
    test('新角色默认 sanityLossRecords / insanityEpisodes 为空', () {
      final c = Character();
      expect(c.sanityLossRecords, isEmpty);
      expect(c.insanityEpisodes, isEmpty);
    });

    test('toJson 包含新字段（空列表）', () {
      final c = Character();
      final json = c.toJson();
      expect(json['sanityLossRecords'], isA<List<dynamic>>());
      expect(json['insanityEpisodes'], isA<List<dynamic>>());
      expect((json['sanityLossRecords'] as List).isEmpty, true);
      expect((json['insanityEpisodes'] as List).isEmpty, true);
    });

    test('fromJson 缺字段时使用空列表（兼容旧备份）', () {
      final json = <String, dynamic>{
        'id': 1,
        'name': '老角色',
        'sanity': 50,
        'maxSanity': 60,
      };
      final c = Character.fromJson(json);
      expect(c.name, '老角色');
      expect(c.sanity, 50);
      expect(c.sanityLossRecords, isEmpty);
      expect(c.insanityEpisodes, isEmpty);
    });

    test('含 SAN 记录的 Character 经 toJson/fromJson 往返保持一致', () {
      final c = Character(name: '测试', sanity: 40, maxSanity: 50, int_: 60);
      c.sanityLossRecords.add(
        SanityLossRecord(
          id: 'sl_1',
          expression: '1d6+1',
          rollDetail: '1d6=4+1=5',
          amount: 5,
          sanityBefore: 50,
          sanityAfter: 45,
          intCheckTriggered: true,
          createdAt: DateTime.parse('2026-06-11T10:00:00Z'),
        ),
      );
      c.insanityEpisodes.add(
        InsanityEpisode(
          id: 'ep_1',
          type: 'temporary',
          symptomRoll: 2,
          durationRoll: 6,
          durationUnit: '轮',
          symptomText: '困惑：困惑地咕哝，持续1d10轮。',
          sanityLoss: 5,
          intCheckRoll: 30,
          intCheckTarget: 60,
          intCheckSuccess: true,
          createdAt: DateTime.parse('2026-06-11T10:00:00Z'),
        ),
      );
      // 同时塞一条技能成长记录，确认多类型字段互不污染
      c.skillCheckRecords.add(
        SkillCheckRecord(
          id: 'r_1',
          skillName: '侦查',
          skillValue: 50,
          roll: 30,
          level: SkillCheckLevel.regular,
          finalSuccess: true,
          ruleProfileId: 'coc7',
          createdAt: DateTime.parse('2026-06-11T10:00:00Z'),
        ),
      );

      final roundtrip = Character.fromJson(c.toJson());
      expect(roundtrip.name, '测试');
      expect(roundtrip.sanity, 40);
      expect(roundtrip.sanityLossRecords.length, 1);
      expect(roundtrip.sanityLossRecords.first.expression, '1d6+1');
      expect(roundtrip.sanityLossRecords.first.amount, 5);
      expect(roundtrip.insanityEpisodes.length, 1);
      expect(roundtrip.insanityEpisodes.first.symptomRoll, 2);
      expect(roundtrip.insanityEpisodes.first.durationRoll, 6);
      expect(roundtrip.insanityEpisodes.first.intCheckSuccess, true);
      expect(roundtrip.skillCheckRecords.length, 1);
    });
  });

  group('InsanityEpisode JSON 兼容', () {
    test('episode.toJson 字段齐全', () {
      final e = InsanityEpisode(
        id: 'x',
        type: 'temporary',
        symptomRoll: 1,
        durationRoll: 10,
        durationUnit: '轮',
        symptomText: '...',
        sanityLoss: 8,
        intCheckRoll: 50,
        intCheckTarget: 60,
        intCheckSuccess: true,
        createdAt: DateTime.parse('2026-06-11T00:00:00Z'),
      );
      final j = e.toJson();
      expect(j['id'], 'x');
      expect(j['type'], 'temporary');
      expect(j['symptomRoll'], 1);
      expect(j['intCheckSuccess'], true);
    });

    test('episode.fromJson 缺字段使用默认值', () {
      final e = InsanityEpisode.fromJson(<String, dynamic>{});
      expect(e.id, '');
      expect(e.type, 'temporary');
      expect(e.durationUnit, '轮');
      expect(e.intCheckRoll, isNull);
      expect(e.intCheckSuccess, isNull);
    });

    test('triggeredInsanity 仅当 type=temporary 且 INT 成功时为 true', () {
      final triggered = InsanityEpisode(
        id: 'a',
        type: 'temporary',
        symptomRoll: 1,
        durationRoll: 1,
        durationUnit: '轮',
        symptomText: '',
        sanityLoss: 5,
        intCheckSuccess: true,
        createdAt: DateTime.now(),
      );
      expect(triggered.triggeredInsanity, true);

      final shielded = InsanityEpisode(
        id: 'b',
        type: 'temporary',
        symptomRoll: 1,
        durationRoll: 1,
        durationUnit: '轮',
        symptomText: '',
        sanityLoss: 5,
        intCheckSuccess: false,
        createdAt: DateTime.now(),
      );
      expect(shielded.triggeredInsanity, false);
    });
  });
}
