import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coc_character/app/data/character.dart';
import 'package:coc_character/app/data/check_rule.dart';
import 'package:coc_character/app/data/skill_check_record.dart';
import 'package:coc_character/app/setting/skill_check_log_controller.dart';

SkillCheckRecord _rec({
  required String skill,
  required SkillCheckLevel level,
  required DateTime at,
  int skillValue = 50,
  int roll = 23,
  bool success = true,
  bool luckSpent = false,
  int? luckCost,
}) {
  return SkillCheckRecord(
    id: 'r${at.microsecondsSinceEpoch}',
    skillName: skill,
    skillValue: skillValue,
    roll: roll,
    level: level,
    finalSuccess: success,
    luckSpent: luckSpent,
    luckCost: luckCost,
    ruleProfileId: 'coc7',
    createdAt: at,
  );
}

void main() {
  group('SkillCheckLogController 筛选', () {
    test('空角色 filteredRecords 为空', () {
      final ctrl = SkillCheckLogController(character: Character());
      expect(ctrl.filteredRecords, isEmpty);
    });

    test('skillName 筛选只匹配同名记录', () {
      final c = Character();
      c.skillCheckRecords.addAll([
        _rec(skill: '心理学', level: SkillCheckLevel.hard, at: DateTime(2026, 6, 12, 21)),
        _rec(skill: '侦查', level: SkillCheckLevel.regular, at: DateTime(2026, 6, 12, 22)),
        _rec(skill: '聆听', level: SkillCheckLevel.failure, at: DateTime(2026, 6, 12, 23)),
      ]);
      final ctrl = SkillCheckLogController(character: c);
      ctrl.setFilter(const SkillCheckLogFilter(skillName: '心理学'));
      expect(ctrl.filteredRecords.length, 1);
      expect(ctrl.filteredRecords.single.skillName, '心理学');
    });

    test('levels 筛选只匹配指定等级集合', () {
      final c = Character();
      c.skillCheckRecords.addAll([
        _rec(skill: 'A', level: SkillCheckLevel.critical, at: DateTime(2026, 6, 12, 21)),
        _rec(skill: 'B', level: SkillCheckLevel.regular, at: DateTime(2026, 6, 12, 22)),
        _rec(skill: 'C', level: SkillCheckLevel.fumble, at: DateTime(2026, 6, 12, 23)),
      ]);
      final ctrl = SkillCheckLogController(character: c);
      ctrl.setFilter(const SkillCheckLogFilter(
        levels: {SkillCheckLevel.critical, SkillCheckLevel.fumble},
      ));
      final got = ctrl.filteredRecords.map((r) => r.level).toSet();
      expect(ctrl.filteredRecords.length, 2);
      expect(got, {SkillCheckLevel.critical, SkillCheckLevel.fumble});
    });

    test('dateRange 仅保留区间内记录', () {
      final c = Character();
      final today = DateTime.now();
      c.skillCheckRecords.addAll([
        _rec(skill: 'today', level: SkillCheckLevel.regular, at: today),
        _rec(
            skill: 'old',
            level: SkillCheckLevel.regular,
            at: today.subtract(const Duration(days: 40))),
      ]);
      final ctrl = SkillCheckLogController(character: c);
      ctrl.setFilter(SkillCheckLogFilter(
        dateRange: DateTimeRange(
          start: DateTime(today.year, today.month, today.day),
          end: today.add(const Duration(minutes: 1)),
        ),
      ));
      expect(ctrl.filteredRecords.length, 1);
      expect(ctrl.filteredRecords.single.skillName, 'today');
    });
  });

  group('SkillCheckLogController 清理', () {
    test('clearFiltered 删除命中条数、保留 skillGrowth、触发 persist', () async {
      final c = Character();
      c.skillCheckRecords.addAll([
        _rec(skill: '心理学', level: SkillCheckLevel.hard, at: DateTime(2026, 6, 12, 21)),
        _rec(skill: '心理学', level: SkillCheckLevel.regular, at: DateTime(2026, 6, 12, 22)),
        _rec(skill: '侦查', level: SkillCheckLevel.failure, at: DateTime(2026, 6, 12, 23)),
      ]);
      c.skillGrowth['心理学'] = SkillGrowthState(skillName: '心理学', successCount: 2);
      c.skillGrowth['侦查'] = SkillGrowthState(skillName: '侦查', failureCount: 1);

      var persisted = 0;
      final ctrl = SkillCheckLogController(
        character: c,
        onPersist: () async => persisted++,
      );
      ctrl.setFilter(const SkillCheckLogFilter(skillName: '心理学'));

      final removed = await ctrl.clearFiltered();
      expect(removed, 2);
      expect(c.skillCheckRecords.length, 1);
      expect(c.skillCheckRecords.single.skillName, '侦查');
      expect(c.skillGrowth.length, 2); // 聚合统计不变
      expect(persisted, 1);
    });

    test('clearFiltered 无命中时不 persist 返回 0', () async {
      final c = Character();
      c.skillCheckRecords.add(
        _rec(skill: '侦查', level: SkillCheckLevel.regular, at: DateTime(2026, 6, 12, 22)),
      );
      var persisted = 0;
      final ctrl = SkillCheckLogController(
        character: c,
        onPersist: () async => persisted++,
      );
      ctrl.setFilter(const SkillCheckLogFilter(skillName: '不存在'));
      final removed = await ctrl.clearFiltered();
      expect(removed, 0);
      expect(persisted, 0);
    });
  });

  group('SkillCheckLogController 导出 CSV', () {
    test('首行为带 BOM 的表头', () {
      final c = Character();
      c.skillCheckRecords.add(
        _rec(skill: '心理学', level: SkillCheckLevel.hard, at: DateTime(2026, 6, 12, 21)),
      );
      final csv = SkillCheckLogController(character: c).exportCsv();
      expect(csv.startsWith('﻿created_at,'), true);
    });

    test('字段顺序固定，第二行可被解析', () {
      final c = Character();
      c.skillCheckRecords.add(_rec(
        skill: '心理学',
        level: SkillCheckLevel.hard,
        at: DateTime(2026, 6, 12, 21),
        skillValue: 60,
        roll: 30,
        luckSpent: true,
        luckCost: 5,
      ));
      final csv = SkillCheckLogController(character: c).exportCsv();
      final match = RegExp(r'^[^\n]+\n([^\n]+)\n').firstMatch(csv);
      expect(match, isNotNull);
      final cols = match!.group(1)!.split(',');
      expect(cols.length, 9);
      expect(cols[1], '心理学'); // skill_name
      expect(cols[2], '60'); // skill_value
      expect(cols[3], '30'); // roll
      expect(cols[4], 'hard'); // level（enum name）
      expect(cols[5], 'true'); // final_success
      expect(cols[6], 'true'); // luck_spent
      expect(cols[7], '5'); // luck_cost
      expect(cols[8], 'coc7'); // rule_profile_id
    });

    test('含逗号/引号的技能名按 RFC 4180 转义', () {
      final c = Character();
      c.skillCheckRecords.add(_rec(
        skill: '技艺（绘画, "国画"）',
        level: SkillCheckLevel.regular,
        at: DateTime(2026, 6, 12, 21),
      ));
      final csv = SkillCheckLogController(character: c).exportCsv();
      expect(csv.contains('"技艺（绘画, ""国画""）"'), true);
    });
  });

  group('SkillCheckLogController 导出 JSON', () {
    test('顶层 schema 字段固定', () {
      final c = Character();
      final json = jsonDecode(SkillCheckLogController(character: c).exportJson());
      expect(json['schema'], 'coccard.skill_check_log.v1');
    });

    test('growth 包含全部 skillGrowth key；records 走筛选', () {
      final c = Character(id: 7, name: '甲');
      c.skillCheckRecords.addAll([
        _rec(skill: '心理学', level: SkillCheckLevel.hard, at: DateTime(2026, 6, 12, 21)),
        _rec(skill: '侦查', level: SkillCheckLevel.regular, at: DateTime(2026, 6, 12, 22)),
      ]);
      c.skillGrowth['心理学'] = SkillGrowthState(skillName: '心理学', successCount: 1);
      c.skillGrowth['侦查'] = SkillGrowthState(skillName: '侦查', successCount: 1);

      final ctrl = SkillCheckLogController(character: c);
      ctrl.setFilter(const SkillCheckLogFilter(skillName: '心理学'));
      final json = jsonDecode(ctrl.exportJson()) as Map<String, dynamic>;

      expect((json['growth'] as Map).length, c.skillGrowth.length);
      expect((json['records'] as List).length, 1); // 仅筛选结果
      expect(json['character']['id'], 7);
      expect(json['character']['name'], '甲');
    });

    test('旧 JSON 导入后再 clearFiltered 不抛异常且 records 仍可序列化', () async {
      // 模拟旧备份：缺 skillCheckRecords / skillGrowth 字段
      final c = Character.fromJson({'id': 1, 'name': '旧角色'});
      c.skillCheckRecords.add(
        _rec(skill: '聆听', level: SkillCheckLevel.regular, at: DateTime(2026, 6, 12, 21)),
      );
      final ctrl = SkillCheckLogController(character: c);
      ctrl.setFilter(const SkillCheckLogFilter(skillName: '聆听'));
      final removed = await ctrl.clearFiltered();
      expect(removed, 1);
      // 仍可正常序列化
      expect(() => jsonEncode(c.toJson()), returnsNormally);
    });
  });
}
