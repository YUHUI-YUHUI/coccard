import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coc_character/app/data/character.dart';
import 'package:coc_character/app/data/character_manager.dart';
import 'package:coc_character/app/pages/home_page.dart';
import 'package:coc_character/app/setting/check_rule_controller.dart';

Future<({CharacterManager manager, CheckRuleController ruleController})>
    _controllers() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final manager = CharacterManager(prefs: prefs);
  await manager.createNewCharacter();
  return (
    manager: manager,
    ruleController: CheckRuleController(prefs: prefs),
  );
}

Future<void> _pumpHome(
  WidgetTester tester,
  CharacterManager manager,
  CheckRuleController ruleController,
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CharacterManager>.value(value: manager),
        ChangeNotifierProvider<CheckRuleController>.value(
          value: ruleController,
        ),
      ],
      child: const MaterialApp(home: HomePage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('快捷技能支持 JSON 往返并兼容旧角色数据', () {
    final character = Character(quickSkills: ['侦查', '聆听']);
    final restored = Character.fromJson(character.toJson());
    final legacy = Character.fromJson({'id': 1, 'name': '旧角色'});

    expect(restored.quickSkills, ['侦查', '聆听']);
    expect(legacy.quickSkills, isEmpty);
  });

  testWidgets('首页显示已选择技能并可直接检定', (tester) async {
    final controllers = await _controllers();
    controllers.manager.updateSkill('侦查', 65);
    await controllers.manager.setQuickSkills(['侦查']);

    await _pumpHome(
      tester,
      controllers.manager,
      controllers.ruleController,
    );

    expect(find.byKey(const Key('quick_skill_card')), findsOneWidget);
    expect(find.text('侦查 65%'), findsOneWidget);

    final quickSkill = find.byKey(const ValueKey('quick_skill_侦查'));
    await tester.ensureVisible(quickSkill);
    await tester.tap(quickSkill);
    await tester.pumpAndSettle();

    expect(find.text('侦查 检定'), findsOneWidget);
    expect(controllers.manager.character.skillCheckRecords, hasLength(1));
    expect(
      controllers.manager.character.skillCheckRecords.single.skillName,
      '侦查',
    );
  });

  testWidgets('用户可搜索并保存首页快捷技能', (tester) async {
    final controllers = await _controllers();
    await _pumpHome(
      tester,
      controllers.manager,
      controllers.ruleController,
    );

    final configure = find.byKey(const Key('configure_quick_skills'));
    await tester.ensureVisible(configure);
    await tester.tap(configure);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('quick_skill_search')),
      '心理学',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('quick_skill_option_心理学')),
    );
    await tester.tap(find.byKey(const Key('save_quick_skills')));
    await tester.pumpAndSettle();

    expect(controllers.manager.character.quickSkills, ['心理学']);
    expect(find.text('心理学 10%'), findsOneWidget);
  });
}
