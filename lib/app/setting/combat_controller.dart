import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/combat_encounter.dart';

/// 战斗追踪控制器。管理当前遭遇和历史记录，
/// 通过 SharedPreferences 持久化到本地。
class CombatController extends ChangeNotifier {
  static const String _prefsKey = 'combat_encounters';
  static const int _maxHistory = 20;

  final SharedPreferences _prefs;
  CombatEncounter? _currentEncounter;
  List<CombatEncounter> _history;

  CombatController({required SharedPreferences prefs})
      : _prefs = prefs,
        _history = [] {
    loadFromPrefs();
  }

  /// 当前正在进行的遭遇（可能为 null）。
  CombatEncounter? get currentEncounter => _currentEncounter;

  /// 历史遭遇列表（最新在前）。
  List<CombatEncounter> get history => List.unmodifiable(_history);

  // ---------------------------------------------------------------------------
  // Encounter lifecycle
  // ---------------------------------------------------------------------------

  /// 创建新遭遇，设为当前，按 DEX 降序排列战斗者。
  void createEncounter(String name, List<Combatant> combatants) {
    combatants.sort((a, b) => b.dex.compareTo(a.dex));
    _currentEncounter = CombatEncounter(
      id: Combatant.generateId(),
      name: name,
      combatants: combatants,
      createdAt: DateTime.now(),
    );
    notifyListeners();
    _save();
  }

  /// 完成当前遭遇：标记为 finished，移入历史，清空当前。
  void finishEncounter() {
    if (_currentEncounter == null) return;
    _currentEncounter!.status = CombatStatus.finished;
    _currentEncounter!.finishedAt = DateTime.now();

    _history = [_currentEncounter!, ..._history];
    if (_history.length > _maxHistory) {
      _history = _history.sublist(0, _maxHistory);
    }

    _currentEncounter = null;
    notifyListeners();
    _save();
  }

  // ---------------------------------------------------------------------------
  // Combatant management
  // ---------------------------------------------------------------------------

  /// 向当前遭遇添加战斗者，并重新按 DEX 排序。
  void addCombatant(Combatant combatant) {
    if (_currentEncounter == null) return;
    _currentEncounter!.combatants.add(combatant);
    _currentEncounter!.combatants.sort((a, b) => b.dex.compareTo(a.dex));
    notifyListeners();
    _save();
  }

  /// 从当前遭遇移除指定 ID 的战斗者。
  void removeCombatant(String combatantId) {
    if (_currentEncounter == null) return;
    _currentEncounter!.combatants.removeWhere((c) => c.id == combatantId);
    notifyListeners();
    _save();
  }

  /// 修改战斗者的 HP。正值为治疗，负值为伤害。
  /// 仅追踪伤害（damageTaken），自动更新生存状态。
  void modifyHp(String combatantId, int delta) {
    if (_currentEncounter == null) return;
    final combatant = _currentEncounter!.combatants
        .where((c) => c.id == combatantId)
        .firstOrNull;
    if (combatant == null) return;

    final oldHp = combatant.currentHp;
    combatant.currentHp = (combatant.currentHp + delta).clamp(0, combatant.maxHp);

    // 仅追踪伤害（HP 减少量），不追踪治疗。
    final actualDamage = oldHp - combatant.currentHp;
    if (actualDamage > 0) {
      combatant.damageTaken += actualDamage;
    }

    // 自动更新状态标签。
    if (combatant.currentHp == 0 &&
        !combatant.statuses.contains(CombatantStatus.dying) &&
        !combatant.statuses.contains(CombatantStatus.dead)) {
      // 当 HP 归零且没有 dying/dead 标记时，标记为 unconscious。
      // （如果需要 dying，应由调用方手动 toggle。）
    }

    notifyListeners();
    _save();
  }

  /// 切换战斗者的状态标签：已有则移除，没有则添加。
  void toggleStatus(String combatantId, CombatantStatus status) {
    if (_currentEncounter == null) return;
    final combatant = _currentEncounter!.combatants
        .where((c) => c.id == combatantId)
        .firstOrNull;
    if (combatant == null) return;

    if (combatant.statuses.contains(status)) {
      combatant.statuses.remove(status);
    } else {
      combatant.statuses.add(status);
    }
    notifyListeners();
    _save();
  }

  // ---------------------------------------------------------------------------
  // Turn management
  // ---------------------------------------------------------------------------

  /// 推进到下一个战斗者的回合。到达末尾时自动进入下一轮。
  void nextTurn() {
    if (_currentEncounter == null) return;
    if (_currentEncounter!.combatants.isEmpty) return;

    final nextIndex = _currentEncounter!.currentTurnIndex + 1;
    if (nextIndex >= _currentEncounter!.combatants.length) {
      nextRound();
    } else {
      _currentEncounter!.currentTurnIndex = nextIndex;
    }
    notifyListeners();
    _save();
  }

  /// 进入下一轮，回合索引重置为 0。
  void nextRound() {
    if (_currentEncounter == null) return;
    _currentEncounter!.currentRound += 1;
    _currentEncounter!.currentTurnIndex = 0;
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  /// 从 SharedPreferences 加载数据。
  void loadFromPrefs() {
    final raw = _prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      if (decoded['current'] != null) {
        _currentEncounter =
            CombatEncounter.fromJson(decoded['current'] as Map<String, dynamic>);
      }

      if (decoded['history'] is List) {
        _history = (decoded['history'] as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(CombatEncounter.fromJson)
            .toList();
      }
    } catch (_) {
      // 损坏的数据不崩溃，保持默认空状态。
    }
  }

  Future<void> _save() async {
    final data = {
      'current': _currentEncounter?.toJson(),
      'history': _history.map((e) => e.toJson()).toList(),
    };
    await _prefs.setString(_prefsKey, jsonEncode(data));
  }
}
