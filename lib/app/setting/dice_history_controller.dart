import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dice_roll_record.dart';

/// 本地骰点历史状态。仅保存到本机 SharedPreferences，
/// 不发起任何网络请求，也不会暴露给其他玩家或设备。
class DiceHistoryController extends ChangeNotifier {
  static const String _prefsKey = 'dice_history_local';
  static const int _maxRecords = 50;

  final SharedPreferences _prefs;
  List<DiceRollRecord> _records;

  DiceHistoryController({required SharedPreferences prefs})
      : _prefs = prefs,
        _records = _load(prefs);

  /// 当前已保存的本地骰点历史（最新在前）。
  List<DiceRollRecord> get records => List.unmodifiable(_records);

  /// 当前已记录条数。
  int get length => _records.length;

  /// 新增一条记录。自动裁剪到 [_maxRecords] 条以内。
  Future<void> addRoll(DiceRollRecord record) async {
    _records = [record, ..._records];
    if (_records.length > _maxRecords) {
      _records = _records.sublist(0, _maxRecords);
    }
    notifyListeners();
    await _persist();
  }

  /// 清空本地历史。聚合统计（如成长计数）不会受到影响。
  Future<void> clear() async {
    if (_records.isEmpty) return;
    _records = [];
    notifyListeners();
    await _prefs.remove(_prefsKey);
  }

  static List<DiceRollRecord> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return <DiceRollRecord>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <DiceRollRecord>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(DiceRollRecord.fromJson)
          .toList();
    } catch (_) {
      return <DiceRollRecord>[];
    }
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(_records.map((r) => r.toJson()).toList());
    await _prefs.setString(_prefsKey, encoded);
  }
}