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

    test('游玩中修改属性保留已受的伤与已损失的 SAN', () {
      manager.setAttributes(
        str: 50, con: 60, siz: 50, dex: 50,
        app: 50, int_: 70, pow: 65, edu: 80,
      );
      manager.takeDamage(3);
      manager.loseSanity(10);

      manager.updateAttribute('力量', 80);

      final c = manager.character;
      expect(c.currentHp, c.maxHp - 3);
      expect(c.sanity, 55); // 65 - 10，不被重置回满
      expect(c.maxSanity, 99);
    });

    test('修改体质调整 HP 上限时按差额平移当前 HP', () {
      manager.setAttributes(
        str: 50, con: 60, siz: 50, dex: 50,
        app: 50, int_: 70, pow: 65, edu: 80,
      );
      manager.takeDamage(4); // 11 → 7

      manager.updateAttribute('体质', 80); // maxHp (50+80)/10 = 13

      final c = manager.character;
      expect(c.maxHp, 13);
      expect(c.currentHp, 9); // 13 - 4
    });

    test('从零手动填卡：填入意志后 SAN 跟随 POW', () {
      manager.updateAttribute('意志', 50);
      final c = manager.character;
      expect(c.sanity, 50);
      expect(c.maxSanity, 99);
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
