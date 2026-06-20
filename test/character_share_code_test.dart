import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coc_character/app/data/character_manager.dart';
import 'package:coc_character/app/pages/start_page.dart';
import 'package:coc_character/app/widgets/app_drawer_widget.dart';

Future<CharacterManager> _newManager() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return CharacterManager(prefs: prefs);
}

void main() {
  group('人物卡角色码', () {
    test('导出后可在另一份本地数据中完整导入', () async {
      final source = await _newManager();
      await source.createNewCharacter();
      source.updateBasicInfo(name: '艾琳', occupation: '记者', age: '27');
      source.setAttributes(
        str: 40,
        con: 50,
        siz: 55,
        dex: 65,
        app: 70,
        int_: 80,
        pow: 60,
        edu: 75,
      );
      source.character.avatarLocalPath = '/only/exists/on/source.png';
      source.updateSkill('侦查', 68);

      final code = source.exportCharacterShareCode();
      expect(code, startsWith(CharacterManager.characterShareCodePrefix));
      expect(code, isNot(contains('\n')));

      final target = await _newManager();
      final imported = await target.importCharacterShareCode(code);

      expect(target.characters, hasLength(1));
      expect(target.character, same(imported));
      expect(imported.name, '艾琳');
      expect(imported.occupation, '记者');
      expect(imported.str, 40);
      expect(imported.skills['侦查'], 68);
      expect(imported.avatarLocalPath, isNull);
      expect(imported.id, 1);
    });

    test('可识别聊天消息中的代码块，并为重复人物分配新 ID', () async {
      final manager = await _newManager();
      await manager.createNewCharacter();
      manager.updateBasicInfo(name: '重复测试');
      final code = manager.exportCharacterShareCode();

      final imported = await manager.importCharacterShareCode(
        '这是人物卡：\n```text\n$code\n```',
      );

      expect(manager.characters, hasLength(2));
      expect(imported.id, 2);
      expect(manager.character.id, 2);
      expect(imported.name, '重复测试');
    });

    test('损坏或非角色码会给出格式错误', () async {
      final manager = await _newManager();

      expect(
        () => manager.importCharacterShareCode('not-a-character-code'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => manager.importCharacterShareCode('COCCARD1.broken'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  testWidgets('开始页可粘贴角色码并导入人物卡', (tester) async {
    final source = await _newManager();
    await source.createNewCharacter();
    source.updateBasicInfo(name: '来自角色码');
    final code = source.exportCharacterShareCode();
    final target = await _newManager();

    await tester.pumpWidget(
      ChangeNotifierProvider<CharacterManager>.value(
        value: target,
        child: MaterialApp(
          home: const StartPage(),
          routes: {
            '/home': (_) => const Scaffold(body: Text('人物卡主页')),
          },
        ),
      ),
    );

    await tester.tap(find.byKey(
      const Key('open_character_share_code_dialog'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('粘贴角色码'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('character_share_code_field')),
      code,
    );
    await tester.tap(find.byKey(
      const Key('import_character_share_code_button'),
    ));
    await tester.pumpAndSettle();

    expect(target.characters, hasLength(1));
    expect(target.character.name, '来自角色码');
  });

  testWidgets('人物卡侧边栏可复制当前角色码', (tester) async {
    final manager = await _newManager();
    await manager.createNewCharacter();
    manager.updateBasicInfo(name: '待分享人物');
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      ChangeNotifierProvider<CharacterManager>.value(
        value: manager,
        child: MaterialApp(
          home: Scaffold(
            drawer: const AppDrawerWidget(),
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                child: const Text('打开菜单'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开菜单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制当前角色码'));
    await tester.pumpAndSettle();

    expect(copiedText, startsWith(CharacterManager.characterShareCodePrefix));
    expect(find.text('角色码已复制到剪贴板'), findsOneWidget);
  });
}
