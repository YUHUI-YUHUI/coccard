import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'character.dart';
import 'skill.dart';
import 'coc_data.dart';

class CharacterManager extends ChangeNotifier {
  static const String _charactersKey = 'coc_characters';
  static const String _currentIndexKey = 'coc_current_index';

  List<Character> _characters = [];
  int _currentIndex = 0;
  final SharedPreferences _prefs;

  CharacterManager({required SharedPreferences prefs}) : _prefs = prefs {
    _loadCharacters();
  }

  Character get character => _characters.isNotEmpty ? _characters[_currentIndex] : Character();
  List<Character> get characters => _characters;

  void _loadCharacters() {
    final String? charsJson = _prefs.getString(_charactersKey);
    if (charsJson != null) {
      final List<dynamic> decoded = json.decode(charsJson);
      _characters = decoded.map((e) => Character.fromJson(e)).toList();
    }
    _currentIndex = _prefs.getInt(_currentIndexKey) ?? 0;
    if (_characters.isEmpty) {
      _characters.add(Character());
    }
    if (_currentIndex >= _characters.length) {
      _currentIndex = 0;
    }
    notifyListeners();
  }

  Future<void> _saveCharacters() async {
    final String charsJson = json.encode(_characters.map((e) => e.toJson()).toList());
    await _prefs.setString(_charactersKey, charsJson);
    await _prefs.setInt(_currentIndexKey, _currentIndex);
  }

  Future<void> createNewCharacter() async {
    _characters.add(Character());
    _currentIndex = _characters.length - 1;
    await _saveCharacters();
    notifyListeners();
  }

  Future<void> selectCharacter(int index) async {
    if (index >= 0 && index < _characters.length) {
      _currentIndex = index;
      await _saveCharacters();
      notifyListeners();
    }
  }

  Future<void> deleteCharacter(int index) async {
    if (_characters.length > 1 && index >= 0 && index < _characters.length) {
      _characters.removeAt(index);
      if (_currentIndex >= _characters.length) {
        _currentIndex = _characters.length - 1;
      }
      await _saveCharacters();
      notifyListeners();
    }
  }

  void updateBasicInfo({
    String? name,
    String? player,
    String? occupation,
    int? selectedOccId,
    String? age,
    String? gender,
    String? residence,
    String? birthplace,
  }) {
    final c = character;
    if (name != null) c.name = name;
    if (player != null) c.player = player;
    if (occupation != null) c.occupation = occupation;
    if (selectedOccId != null) c.selectedOccId = selectedOccId;
    if (age != null) c.age = age;
    if (gender != null) c.gender = gender;
    if (residence != null) c.residence = residence;
    if (birthplace != null) c.birthplace = birthplace;
    _saveCharacters();
    notifyListeners();
  }

  void updateAttribute(String attr, int value) {
    final c = character;
    switch (attr) {
      case '力量': c.str = value; break;
      case '体质': c.con = value; break;
      case '体型': c.siz = value; break;
      case '敏捷': c.dex = value; break;
      case '外貌': c.app = value; break;
      case '智力': c.int_ = value; break;
      case '意志': c.pow = value; break;
      case '教育': c.edu = value; break;
    }
    _calculateDerivedStats();
    _saveCharacters();
    notifyListeners();
  }

  void setAttributes({
    required int str,
    required int con,
    required int siz,
    required int dex,
    required int app,
    required int int_,
    required int pow,
    required int edu,
  }) {
    final c = character;
    c.str = str;
    c.con = con;
    c.siz = siz;
    c.dex = dex;
    c.app = app;
    c.int_ = int_;
    c.pow = pow;
    c.edu = edu;
    _calculateDerivedStats();
    _saveCharacters();
    notifyListeners();
  }

  void _calculateDerivedStats() {
    final c = character;
    c.maxHp = ((c.siz + c.con) / 10).floor();
    c.currentHp = c.maxHp;
    c.maxMp = (c.pow / 5).floor();
    c.currentMp = c.maxMp;
    c.maxSanity = 99 - c.pow;
    c.sanity = c.maxSanity;
    c.luck = ((Random().nextInt(6) + 1) + (Random().nextInt(6) + 1) + (Random().nextInt(6) + 1)) * 5;
    c.move = ((c.dex + c.siz) / 10).floor();
    c.build = ((c.str + c.siz) / 10).floor() - 2;

    final db = c.str + c.siz;
    if (db >= 2 && db <= 12) {
      c.damageBonus = '-1D6';
    } else if (db >= 13 && db <= 16) {
      c.damageBonus = '-1D4';
    } else if (db >= 17 && db <= 24) {
      c.damageBonus = '0';
    } else if (db >= 25 && db <= 32) {
      c.damageBonus = '+1D4';
    } else if (db >= 33 && db <= 40) {
      c.damageBonus = '+1D6';
    } else if (db >= 41 && db <= 56) {
      c.damageBonus = '+2D6';
    } else if (db >= 57) {
      c.damageBonus = '+3D6';
    } else {
      c.damageBonus = '0';
    }
    c.luckDice = 3;
  }

  void rollAttributes() {
    final c = character;
    final r = Random();
    c.str = ((r.nextInt(6) + 1) + (r.nextInt(6) + 1) + (r.nextInt(6) + 1)) * 5;
    c.con = ((r.nextInt(6) + 1) + (r.nextInt(6) + 1) + (r.nextInt(6) + 1)) * 5;
    c.siz = ((r.nextInt(6) + 1) + (r.nextInt(6) + 1) + (r.nextInt(6) + 1)) * 5;
    c.dex = ((r.nextInt(6) + 1) + (r.nextInt(6) + 1) + (r.nextInt(6) + 1)) * 5;
    c.app = ((r.nextInt(6) + 1) + (r.nextInt(6) + 1) + (r.nextInt(6) + 1)) * 5;
    c.int_ = ((r.nextInt(6) + 1) + (r.nextInt(6) + 1) + (r.nextInt(6) + 1)) * 5;
    c.pow = ((r.nextInt(6) + 1) + (r.nextInt(6) + 1) + (r.nextInt(6) + 1)) * 5;
    c.edu = ((r.nextInt(6) + 1) + (r.nextInt(6) + 1) + (r.nextInt(6) + 1)) * 5;
    _calculateDerivedStats();
    _saveCharacters();
    notifyListeners();
  }

  void applyOccupation(Occupation occ) {
    // 重置之前消耗的点数
    resetSkillPoints();

    final c = character;
    c.occupation = occ.n;
    c.selectedOccId = occ.id;
    c.creditMin = occ.min;
    c.creditMax = occ.max;

    // 计算职业点数和兴趣点数
    _calculateOccupationAndInterestPoints(occ);

    final occSkills = occ.sk.split('，').map((s) => s.trim()).toList();
    for (final skillName in occSkills) {
      if (skillName.isNotEmpty && !skillName.startsWith('任意') && !skillName.startsWith('两项')) {
        final skillDef = SKILL_DEFS.where((s) => s.key == skillName).firstOrNull;
        if (skillDef != null) {
          c.skills[skillName] = skillDef.baseHalf;
        }
      }
    }
    c.skills['母语'] = c.edu;
    _saveCharacters();
    notifyListeners();
  }

  void _calculateOccupationAndInterestPoints(Occupation occ) {
    final c = character;
    // 解析职业属性公式，如 "教育×4" 或 "教育×2＋敏捷×2"
    final attrParts = occ.attr.split('＋');
    int occPoints = 0;
    for (final part in attrParts) {
      final trimmed = part.trim();
      if (trimmed.contains('力量')) {
        occPoints += c.str * _extractMultiplier(trimmed);
      } else if (trimmed.contains('体质')) {
        occPoints += c.con * _extractMultiplier(trimmed);
      } else if (trimmed.contains('体型')) {
        occPoints += c.siz * _extractMultiplier(trimmed);
      } else if (trimmed.contains('敏捷')) {
        occPoints += c.dex * _extractMultiplier(trimmed);
      } else if (trimmed.contains('外貌')) {
        occPoints += c.app * _extractMultiplier(trimmed);
      } else if (trimmed.contains('智力')) {
        occPoints += c.int_ * _extractMultiplier(trimmed);
      } else if (trimmed.contains('意志')) {
        occPoints += c.pow * _extractMultiplier(trimmed);
      } else if (trimmed.contains('教育')) {
        occPoints += c.edu * _extractMultiplier(trimmed);
      }
    }

    c.occupationPoint = occPoints;
    // 兴趣点数 = 智力×2
    c.interestPoint = c.int_ * 2;
  }

  int _extractMultiplier(String part) {
    // 提取乘数，如 "教育×4" 返回 4
    final match = RegExp(r'×(\d+)').firstMatch(part);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  void updateBackstory(String backstory) {
    character.backstory = backstory;
    _saveCharacters();
    notifyListeners();
  }

  void updateNotes(String notes) {
    character.notes = notes;
    _saveCharacters();
    notifyListeners();
  }

  void updateFinance({int? cash, int? spending, int? assets}) {
    final c = character;
    if (cash != null) c.cash = cash;
    if (spending != null) c.spending = spending;
    if (assets != null) c.assets = assets;
    _saveCharacters();
    notifyListeners();
  }

  void addWeapon(CharacterWeapon weapon) {
    character.weapons.add(weapon);
    _saveCharacters();
    notifyListeners();
  }

  void updateWeapon(int index, CharacterWeapon weapon) {
    if (index >= 0 && index < character.weapons.length) {
      character.weapons[index] = weapon;
      _saveCharacters();
      notifyListeners();
    }
  }

  void deleteWeapon(int index) {
    if (index >= 0 && index < character.weapons.length) {
      character.weapons.removeAt(index);
      _saveCharacters();
      notifyListeners();
    }
  }

  void updateSkill(String skillName, int value) {
    character.skills[skillName] = value;
    _saveCharacters();
    notifyListeners();
  }

  /// 添加技能点数
  /// [skillName] 技能名称
  /// [amount] 加点数额
  /// [useOccupationPoint] true=使用职业点数, false=使用兴趣点数
  /// 返回是否成功
  bool addSkillPoints(String skillName, int amount, bool useOccupationPoint) {
    final c = character;
    if (amount <= 0) return false;

    if (useOccupationPoint) {
      final remaining = c.occupationPoint - c.occupationPointSpent;
      if (amount > remaining) return false;
      c.occupationPointSpent += amount;
    } else {
      final remaining = c.interestPoint - c.interestPointSpent;
      if (amount > remaining) return false;
      c.interestPointSpent += amount;
    }

    // 计算新技能值 = 当前值 + 加点数
    final currentValue = c.skills[skillName] ?? 0;
    c.skills[skillName] = currentValue + amount;
    _saveCharacters();
    notifyListeners();
    return true;
  }

  /// 重置职业时调用的点数重置
  void resetSkillPoints() {
    final c = character;
    c.occupationPointSpent = 0;
    c.interestPointSpent = 0;
    _saveCharacters();
    notifyListeners();
  }

  void useLuckDice() {
    if (character.luckDice > 0) {
      character.luckDice--;
      _saveCharacters();
      notifyListeners();
    }
  }

  void resetLuckDice() {
    character.luckDice = 3;
    _saveCharacters();
    notifyListeners();
  }

  void loseSanity(int amount) {
    character.sanity = (character.sanity - amount).clamp(0, character.maxSanity);
    _saveCharacters();
    notifyListeners();
  }

  void takeDamage(int amount) {
    character.currentHp = (character.currentHp - amount).clamp(0, character.maxHp);
    _saveCharacters();
    notifyListeners();
  }

  void heal(int amount) {
    character.currentHp = (character.currentHp + amount).clamp(0, character.maxHp);
    _saveCharacters();
    notifyListeners();
  }

  void useMp(int amount) {
    character.currentMp = (character.currentMp - amount).clamp(0, character.maxMp);
    _saveCharacters();
    notifyListeners();
  }

  void restoreMp(int amount) {
    character.currentMp = (character.currentMp + amount).clamp(0, character.maxMp);
    _saveCharacters();
    notifyListeners();
  }
}
