import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coc_character/app/data/combat_encounter.dart';
import 'package:coc_character/app/pages/combat_list_page.dart';
import 'package:coc_character/app/setting/combat_controller.dart';

Future<CombatController> _controller() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return CombatController(prefs: prefs);
}

Future<void> _pumpPage(WidgetTester tester, CombatController controller) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<CombatController>.value(
      value: controller,
      child: const MaterialApp(home: CombatListPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Combatant _combatant(String id, String name, int dex, int hp) => Combatant(
      id: id,
      name: name,
      type: CombatantType.npc,
      dex: dex,
      maxHp: hp,
      currentHp: hp,
    );

void main() {
  testWidgets('空状态显示提示文案与新建按钮', (tester) async {
    final controller = await _controller();
    await _pumpPage(tester, controller);

    expect(find.text('暂无战斗记录'), findsOneWidget);
    expect(find.text('新建战斗'), findsOneWidget);
  });

  testWidgets('点击新建战斗弹出对话框并创建进行中遭遇', (tester) async {
    final controller = await _controller();
    await _pumpPage(tester, controller);

    await tester.tap(find.text('新建战斗'));
    await tester.pumpAndSettle();

    // 对话框出现
    expect(find.text('战斗名称'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '图书馆遭遇战');
    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();

    // 创建后列表出现进行中的战斗卡片
    expect(controller.currentEncounter, isNotNull);
    expect(controller.currentEncounter!.name, '图书馆遭遇战');
    expect(find.text('图书馆遭遇战'), findsOneWidget);
    expect(find.text('进行中'), findsOneWidget);
  });

  testWidgets('进行中战斗可点击「结束」移入历史', (tester) async {
    final controller = await _controller();
    controller.createEncounter('遭遇战', [_combatant('c1', '渔夫', 50, 12)]);
    await _pumpPage(tester, controller);

    expect(find.text('进行中'), findsOneWidget);

    await tester.tap(find.text('结束'));
    await tester.pumpAndSettle();

    // 确认对话框
    expect(find.text('将当前战斗标记为已结束并移入历史，确认？'), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(TextButton, '结束'),
    ));
    await tester.pumpAndSettle();

    expect(controller.currentEncounter, isNull);
    expect(controller.history.length, 1);
    expect(find.text('已结束'), findsOneWidget);
    expect(find.textContaining('历史战斗'), findsOneWidget);
  });

  testWidgets('历史战斗渲染轮数与参战者数量', (tester) async {
    final controller = await _controller();
    controller.createEncounter('已结束的战斗', [
      _combatant('c1', '渔夫', 50, 12),
      _combatant('c2', '猎犬', 40, 8),
    ]);
    controller.nextRound(); // 进入第 2 轮
    controller.finishEncounter();
    await _pumpPage(tester, controller);

    expect(find.text('已结束的战斗'), findsOneWidget);
    // 2 轮 · 2 名参战者
    expect(find.textContaining('2 轮 · 2 名参战者'), findsOneWidget);
  });
}
