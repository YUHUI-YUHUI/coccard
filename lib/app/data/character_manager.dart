import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'character.dart';
import 'check_rule.dart';
import 'skill.dart';
import 'skill_check_record.dart';
import 'coc_data.dart';

class DeletedCharacter {
  final Character character;
  final int index;
  final int? currentCharacterId;

  const DeletedCharacter({
    required this.character,
    required this.index,
    required this.currentCharacterId,
  });
}

class CharacterManager extends ChangeNotifier {
  static const String _charactersKey = 'coc_characters';
  static const String _currentIndexKey = 'coc_current_index';

  List<Character> _characters = [];
  int _currentIndex = 0;
  final SharedPreferences _prefs;

  CharacterManager({required SharedPreferences prefs}) : _prefs = prefs {
    _loadCharacters();
  }

  int _nextId() {
    if (_characters.isEmpty) return 1;
    return _characters.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  Character get character =>
      _characters.isNotEmpty ? _characters[_currentIndex] : Character();
  List<Character> get characters => _characters;
  bool get hasCharacters => _characters.isNotEmpty;

  void _loadCharacters() {
    final String? charsJson = _prefs.getString(_charactersKey);
    if (charsJson != null) {
      final List<dynamic> decoded = json.decode(charsJson);
      _characters = decoded.map((e) => Character.fromJson(e)).toList();
    }
    // 给旧数据中 id=0 的角色补上唯一 ID
    for (final c in _characters) {
      if (c.id == 0) c.id = _nextId();
    }
    _currentIndex = _prefs.getInt(_currentIndexKey) ?? 0;
    if (_currentIndex >= _characters.length) {
      _currentIndex = 0;
    }
    notifyListeners();
  }

  Future<void> _saveCharacters() async {
    final String charsJson =
        json.encode(_characters.map((e) => e.toJson()).toList());
    await _prefs.setString(_charactersKey, charsJson);
    await _prefs.setInt(_currentIndexKey, _currentIndex);
  }

  Future<void> createNewCharacter() async {
    final newChar = Character(id: _nextId());
    _characters.add(newChar);
    _currentIndex = _characters.length - 1;
    await _saveCharacters();
    notifyListeners();
  }

  /// 按 ID 查找并切换角色
  Future<void> selectCharacter(int id) async {
    final idx = _characters.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      _currentIndex = idx;
      await _saveCharacters();
      notifyListeners();
    }
  }

  int _nextIdFrom(Set<int> usedIds) {
    var id = 1;
    while (usedIds.contains(id)) {
      id++;
    }
    return id;
  }

  int _clampIndex(int index, int maxIndex) {
    if (index < 0) return 0;
    if (index > maxIndex) return maxIndex;
    return index;
  }

  Future<DeletedCharacter?> deleteCharacter(int index) async {
    if (index < 0 || index >= _characters.length) {
      return null;
    }

    final isDeletingCurrent = index == _currentIndex;
    final currentCharacterId =
        _characters.isEmpty ? null : _characters[_currentIndex].id;
    final deletedCharacter = _characters.removeAt(index);

    if (_characters.isEmpty) {
      _currentIndex = 0;
    } else if (isDeletingCurrent) {
      _currentIndex =
          index >= _characters.length ? _characters.length - 1 : index;
    } else if (index < _currentIndex) {
      _currentIndex--;
    } else if (_currentIndex >= _characters.length) {
      _currentIndex = _characters.length - 1;
    }

    await _saveCharacters();
    notifyListeners();
    return DeletedCharacter(
      character: deletedCharacter,
      index: index,
      currentCharacterId: currentCharacterId,
    );
  }

  Future<void> restoreDeletedCharacter(DeletedCharacter deleted) async {
    final usedIds = _characters.map((c) => c.id).toSet();
    if (deleted.character.id == 0 || usedIds.contains(deleted.character.id)) {
      deleted.character.id = _nextIdFrom(usedIds);
    }

    final insertIndex = _clampIndex(deleted.index, _characters.length);
    _characters.insert(insertIndex, deleted.character);

    final restoredCurrentIndex = _characters.indexWhere(
      (c) => c.id == deleted.currentCharacterId,
    );
    _currentIndex =
        restoredCurrentIndex >= 0 ? restoredCurrentIndex : insertIndex;

    await _saveCharacters();
    notifyListeners();
  }

  String exportCharactersBackupJson() {
    final backup = {
      'version': 1,
      'app': 'coccard',
      'exportedAt': DateTime.now().toIso8601String(),
      'currentIndex': _currentIndex,
      'characters': _characters.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  Future<int> importCharactersBackupJson(
    String rawJson, {
    required bool replaceExisting,
  }) async {
    final decoded = json.decode(rawJson);
    late final List<dynamic> characterJsonList;
    var importedCurrentIndex = 0;

    if (decoded is List) {
      characterJsonList = decoded;
    } else if (decoded is Map) {
      final backup = Map<String, dynamic>.from(decoded);
      final charactersValue = backup['characters'];
      if (charactersValue is! List) {
        throw const FormatException('备份中没有找到角色列表');
      }
      characterJsonList = charactersValue;
      final currentIndexValue = backup['currentIndex'];
      if (currentIndexValue is int) {
        importedCurrentIndex = currentIndexValue;
      }
    } else {
      throw const FormatException('备份格式不正确');
    }

    final importedCharacters = characterJsonList.map((item) {
      if (item is! Map) {
        throw const FormatException('角色数据格式不正确');
      }
      return Character.fromJson(Map<String, dynamic>.from(item));
    }).toList();

    if (importedCharacters.isEmpty) {
      return 0;
    }

    if (replaceExisting) {
      _characters = [];
      _currentIndex = 0;
    }

    final usedIds = _characters.map((c) => c.id).toSet();
    for (final character in importedCharacters) {
      if (character.id == 0 || usedIds.contains(character.id)) {
        character.id = _nextIdFrom(usedIds);
      }
      usedIds.add(character.id);
      _characters.add(character);
    }

    if (replaceExisting) {
      _currentIndex = _clampIndex(importedCurrentIndex, _characters.length - 1);
    } else if (_characters.length == importedCharacters.length) {
      _currentIndex = 0;
    }

    await _saveCharacters();
    notifyListeners();
    return importedCharacters.length;
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
    // 仅在 luck 未初始化（=0）时自动投出，避免覆盖调用方已设置的值。
    if (c.luck == 0) {
      c.luck = ((Random().nextInt(6) + 1) + (Random().nextInt(6) + 1) + (Random().nextInt(6) + 1)) * 5;
    }
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

    // 属性变化时重新计算职业点数和兴趣点数
    _recalculateOccupationPoints();
  }

  void _recalculateOccupationPoints() {
    final c = character;
    if (c.selectedOccId != null) {
      final occ = OCCUPATIONS.where((o) => o.id == c.selectedOccId).firstOrNull;
      if (occ != null) {
        _calculateOccupationAndInterestPoints(occ);
      }
    } else {
      c.interestPoint = c.int_ * 2;
    }
  }

  void rollAttributes() {
    final c = character;
    final r = Random();
    int d6() => r.nextInt(6) + 1;
    int d6x3x5() => (d6() + d6() + d6()) * 5;
    int d6x2p6x5() => (d6() + d6() + 6) * 5;
    c.str = d6x3x5();
    c.con = d6x3x5();
    c.siz = d6x2p6x5();
    c.dex = d6x3x5();
    c.app = d6x3x5();
    c.int_ = d6x2p6x5();
    c.pow = d6x3x5();
    c.edu = d6x2p6x5();
    c.luck = 0; // 让 _calculateDerivedStats 重新投运气
    _calculateDerivedStats();
    _saveCharacters();
    notifyListeners();
  }

  void applyOccupation(Occupation occ) {
    final c = character;
    // 重置之前消耗的点数和技能
    c.occupationPointSpent = 0;
    c.interestPointSpent = 0;
    c.skills.clear();

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

  void updateAppearance(String appearance) {
    character.appearance = appearance;
    _saveCharacters();
    notifyListeners();
  }

  /// 设置头像。[localPath] 为 app docs 中的绝对路径（可为 null 表示清除）；
  /// [url] 可选地保留原始远程地址供调试。
  void setAvatar({String? localPath, String? url}) {
    character.avatarLocalPath = localPath;
    character.avatarUrl = url;
    _saveCharacters();
    notifyListeners();
  }

  void updateItems(List<CharacterItem> items) {
    character.items = items;
    _saveCharacters();
    notifyListeners();
  }

  void addItem(CharacterItem item) {
    character.items.add(item);
    _saveCharacters();
    notifyListeners();
  }

  void updateItem(int index, CharacterItem item) {
    if (index >= 0 && index < character.items.length) {
      character.items[index] = item;
      _saveCharacters();
      notifyListeners();
    }
  }

  void deleteItem(int index) {
    if (index >= 0 && index < character.items.length) {
      character.items.removeAt(index);
      _saveCharacters();
      notifyListeners();
    }
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

    // 计算新技能值 = 当前值 + 加点数（未分配的技能使用基础值）
    final skillDef = SKILL_DEFS.where((s) => s.key == skillName).firstOrNull;
    final baseValue = skillDef?.baseHalf ?? 0;
    final currentValue = c.skills[skillName] ?? baseValue;
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

  bool spendLuck(int amount) {
    if (amount <= 0) return false;
    final c = character;
    if (c.luck < amount) return false;

    c.luck -= amount;
    _saveCharacters();
    notifyListeners();
    return true;
  }

  static const int _maxSkillCheckRecords = 200;

  /// 记录一次技能检定，更新成长统计；超出 [_maxSkillCheckRecords] 时裁掉最旧的日志。
  /// 聚合统计 (skillGrowth) 不随裁剪而丢失。
  void recordSkillCheck(SkillCheckResult result, String skillName) {
    if (_characters.isEmpty) return;
    final c = character;
    final now = DateTime.now();
    final record = SkillCheckRecord(
      id: '${now.microsecondsSinceEpoch}',
      skillName: skillName,
      skillValue: result.skillValue,
      roll: result.roll,
      level: result.level,
      finalSuccess: result.isSuccess,
      ruleProfileId: result.ruleProfileId,
      createdAt: now,
    );

    c.skillCheckRecords.add(record);
    if (c.skillCheckRecords.length > _maxSkillCheckRecords) {
      c.skillCheckRecords.removeRange(
        0,
        c.skillCheckRecords.length - _maxSkillCheckRecords,
      );
    }

    final growth = c.skillGrowth[skillName] ??
        SkillGrowthState(skillName: skillName);
    if (result.isSuccess) {
      growth.successCount += 1;
      growth.growthMarked = true;
    } else {
      growth.failureCount += 1;
    }
    growth.lastCheckedAt = now;
    c.skillGrowth[skillName] = growth;

    _saveCharacters();
    notifyListeners();
  }

  /// 列出所有 growthMarked 为 true 的技能（用于幕间成长页）。
  List<({String skillName, SkillGrowthState state})> markedGrowthSkills() {
    if (_characters.isEmpty) return const [];
    final c = character;
    final entries = c.skillGrowth.entries
        .where((e) => e.value.growthMarked)
        .map((e) => (skillName: e.key, state: e.value))
        .toList();
    entries.sort((a, b) => a.skillName.compareTo(b.skillName));
    return entries;
  }

  /// 对单个技能执行一次幕间成长检定。
  ///
  /// 行为：
  /// 1. 掷 1D100，结果必须大于当前技能值才成长。
  /// 2. 成长成功后 +1D10，清除 growthMarked，写入 lastGrowthAt。
  /// 3. 不成长时保留标记，允许下次幕间再检。
  /// 4. 同步追加一条 skillCheckRecord 记录以保留可追溯日志。
  ///
  /// 返回 [SkillGrowthCheck] 结果便于 UI 展示。
  SkillGrowthCheck performGrowthCheck(String skillName) {
    if (_characters.isEmpty) {
      throw StateError('当前没有角色，无法进行成长检定');
    }
    final c = character;
    final state = c.skillGrowth[skillName];
    if (state == null || !state.growthMarked) {
      throw StateError('技能 "$skillName" 未标记成长，无需检定');
    }
    final skillValue = c.skills[skillName] ?? 0;
    final random = Random();
    final roll = random.nextInt(100) + 1;
    final dieRoll = random.nextInt(10) + 1;
    final result = SkillGrowthCheck.evaluate(
      skillName: skillName,
      skillValue: skillValue,
      roll: roll,
      dieRoll: dieRoll,
    );
    final now = result.checkedAt;
    if (result.grown) {
      c.skills[skillName] = result.newSkillValue;
      state.growthMarked = false;
      state.lastGrowthAt = now;
      c.skillGrowth[skillName] = state;
    }
    state.lastCheckedAt = now;
    // 追加成长检定日志（level 用 extreme 以便高亮）
    c.skillCheckRecords.add(
      SkillCheckRecord(
        id: 'growth_${now.microsecondsSinceEpoch}',
        skillName: skillName,
        skillValue: skillValue,
        roll: roll,
        level: result.grown
            ? SkillCheckLevel.critical
            : SkillCheckLevel.failure,
        finalSuccess: result.grown,
        ruleProfileId: 'growth',
        createdAt: now,
      ),
    );
    if (c.skillCheckRecords.length > _maxSkillCheckRecords) {
      c.skillCheckRecords.removeRange(
        0,
        c.skillCheckRecords.length - _maxSkillCheckRecords,
      );
    }
    _saveCharacters();
    notifyListeners();
    return result;
  }

  /// 玩家花费幸运补正后，将最近一次检定记录改写为成功，并补登成长标记。
  void markLastCheckLuckSpent({
    required String skillName,
    required int luckCost,
  }) {
    if (_characters.isEmpty) return;
    final c = character;
    if (c.skillCheckRecords.isEmpty) return;

    final lastIndex = c.skillCheckRecords.length - 1;
    final last = c.skillCheckRecords[lastIndex];
    if (last.skillName != skillName) return;

    c.skillCheckRecords[lastIndex] = SkillCheckRecord(
      id: last.id,
      skillName: last.skillName,
      skillValue: last.skillValue,
      roll: last.roll,
      level: last.level,
      finalSuccess: true,
      luckSpent: true,
      luckCost: luckCost,
      ruleProfileId: last.ruleProfileId,
      createdAt: last.createdAt,
    );

    final growth = c.skillGrowth[skillName] ??
        SkillGrowthState(skillName: skillName);
    if (!last.finalSuccess) {
      growth.failureCount = (growth.failureCount - 1).clamp(0, 1 << 30);
      growth.successCount += 1;
      growth.growthMarked = true;
      c.skillGrowth[skillName] = growth;
    }

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
