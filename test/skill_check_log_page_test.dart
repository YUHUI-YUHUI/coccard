import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coc_character/app/data/character.dart';
import 'package:coc_character/app/data/character_manager.dart';
import 'package:coc_character/app/data/check_rule.dart';
import 'package:coc_character/app/data/skill_check_record.dart';
import 'package:coc_character/app/pages/skill_check_log_page.dart';

Future<CharacterManager> _managerWithRecords() async {
  final char = Character(id: 1, name: '测试');
  char.skillCheckRecords.add(SkillCheckRecord(
    id: 'r1',
    skillName: '心理学',
    skillValue: 50,
    roll: 23,
    level: SkillCheckLevel.hard,
    finalSuccess: true,
    ruleProfileId: 'coc7',
    createdAt: DateTime(2026, 6, 12, 21, 50),
  ));
  SharedPreferences.setMockInitialValues({
    'coc_characters': jsonEncode([char.toJson()]),
    'coc_current_index': 0,
  });
  final prefs = await SharedPreferences.getInstance();
  return CharacterManager(prefs: prefs);
}

Future<void> _pumpPage(WidgetTester tester, CharacterManager manager) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<CharacterManager>.value(
      value: manager,
      child: const MaterialApp(home: SkillCheckLogPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('进入页面默认展开筛选条', (tester) async {
    final manager = await _managerWithRecords();
    await _pumpPage(tester, manager);

    expect(find.text('技能'), findsOneWidget);
    expect(find.text('等级'), findsOneWidget);
    expect(find.text('时间'), findsOneWidget);
  });

  testWidgets('点击 delete_sweep 弹出清理确认对话框', (tester) async {
    final manager = await _managerWithRecords();
    await _pumpPage(tester, manager);

    await tester.tap(find.byIcon(Icons.delete_sweep));
    await tester.pumpAndSettle();

    expect(find.text('确认'), findsOneWidget);
    expect(find.textContaining('聚合统计'), findsOneWidget);
  });

  testWidgets('点击 ios_share 弹出导出底部菜单', (tester) async {
    final manager = await _managerWithRecords();
    await _pumpPage(tester, manager);

    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pumpAndSettle();

    expect(find.text('复制 CSV'), findsOneWidget);
    expect(find.text('复制 JSON'), findsOneWidget);
    expect(find.text('保存到应用文档目录'), findsOneWidget);
  });

  testWidgets('点击 filter_alt 可折叠筛选条', (tester) async {
    final manager = await _managerWithRecords();
    await _pumpPage(tester, manager);

    expect(find.text('等级'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.filter_alt));
    await tester.pumpAndSettle();
    expect(find.text('等级'), findsNothing);
  });
}
