import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coc_character/app/data/character_manager.dart';

void main() {
  group('CharacterManager 派生属性与 SAN 规则', () {
    late CharacterManager manager;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      manager = CharacterManager(prefs: prefs);
      await manager.createNewCharacter();
    });

    test('setAttributes 后起始 SAN = POW，上限 = 99（神话 0）', () {
      manager.setAttributes(
        str: 50, con: 60, siz: 50, dex: 50,
        app: 50, int_: 70, pow: 65, edu: 80,
      );
      final c = manager.character;
      expect(c.sanity, 65);
      expect(c.maxSanity, 99);
      expect(c.maxHp, 11);
      expect(c.currentHp, 11);
      expect(c.maxMp, 13);
      expect(c.currentMp, 13);
    });

    test('克苏鲁神话技能压低 SAN 上限并夹住当前 SAN', () {
      manager.setAttributes(
        str: 50, con: 60, siz: 50, dex: 50,
        app: 50, int_: 70, pow: 90, edu: 80,
      );
      expect(manager.character.sanity, 90);

      manager.updateSkill('克苏鲁神话', 15);

      final c = manager.character;
      expect(c.maxSanity, 84);
      expect(c.sanity, 84); // 90 被压回新上限
    });
  });
}
