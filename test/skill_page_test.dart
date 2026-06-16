import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coc_character/app/data/character_manager.dart';
import 'package:coc_character/app/pages/skill_page.dart';
import 'package:coc_character/app/setting/check_rule_controller.dart';

Future<void> _pumpSkillPage(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final manager = CharacterManager(prefs: prefs);
  final checkRuleController = CheckRuleController(prefs: prefs);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CharacterManager>.value(value: manager),
        ChangeNotifierProvider<CheckRuleController>.value(
          value: checkRuleController,
        ),
      ],
      child: MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          );
        },
        home: const SkillPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('技能页顶部筛选标签在窄屏高字号下可滚动展示', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpSkillPage(tester);

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.isScrollable, isTrue);
    expect(tabBar.tabAlignment, TabAlignment.start);
    expect(tester.takeException(), isNull);

    for (final label in ['本职', '已加点', '推荐未加', '全部']) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
