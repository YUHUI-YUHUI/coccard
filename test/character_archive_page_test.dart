import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coc_character/app/data/character.dart';
import 'package:coc_character/app/data/character_manager.dart';
import 'package:coc_character/app/pages/character_archive_page.dart';

Future<CharacterManager> _manager() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return CharacterManager(prefs: prefs);
}

void main() {
  test('人物卡模组字段兼容旧数据并可序列化', () {
    final legacy = Character.fromJson({'id': 1, 'name': '旧人物'});
    expect(legacy.moduleName, isEmpty);
    expect(legacy.moduleStatus, '进行中');

    final restored = Character.fromJson({
      ...legacy.toJson(),
      'moduleName': '无名之城',
      'moduleStatus': '已结团',
    });
    expect(restored.moduleName, '无名之城');
    expect(restored.moduleStatus, '已结团');
  });

  test('可按 ID 更新任意人物卡的模组对应', () async {
    final manager = await _manager();
    await manager.createNewCharacter();
    manager.updateBasicInfo(name: '艾琳');
    final id = manager.character.id;

    await manager.updateCharacterModule(
      id,
      moduleName: '  无名之城  ',
      moduleStatus: '待开团',
    );

    expect(manager.characters.single.moduleName, '无名之城');
    expect(manager.characters.single.moduleStatus, '待开团');
  });

  testWidgets('整理页展示 PC 形象、按模组分组并支持修改对应', (tester) async {
    final manager = await _manager();
    await manager.createNewCharacter();
    manager.updateBasicInfo(name: '艾琳', occupation: '记者');
    await manager.updateCharacterModule(
      manager.character.id,
      moduleName: '无名之城',
      moduleStatus: '进行中',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<CharacterManager>.value(
        value: manager,
        child: const MaterialApp(home: CharacterArchivePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('人物卡与模组'), findsOneWidget);
    expect(find.text('无名之城'), findsOneWidget);
    expect(find.text('艾琳'), findsOneWidget);
    expect(find.text('添加 PC 形象'), findsOneWidget);
    expect(find.text('进行中'), findsOneWidget);

    await tester
        .tap(find.byKey(ValueKey('edit_module_${manager.character.id}')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('module_name_field')), '古屋怪事');
    await tester.tap(find.byKey(const Key('save_module_button')));
    await tester.pumpAndSettle();

    expect(manager.character.moduleName, '古屋怪事');
    expect(find.text('古屋怪事'), findsOneWidget);
    expect(find.text('无名之城'), findsNothing);
  });
}
