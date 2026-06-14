import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/character.dart';
import '../data/check_rule.dart';
import '../data/skill_check_record.dart';

/// 技能检定日志的筛选条件。一期仅作为 UI 层临时状态，不持久化。
///
/// - [skillName] 为 null 表示不限技能。
/// - [levels] 为空集表示不限等级。
/// - [dateRange] 为 null 表示不限时间；区间为闭区间 [start, end]。
class SkillCheckLogFilter {
  final String? skillName;
  final Set<SkillCheckLevel> levels;
  final DateTimeRange? dateRange;

  const SkillCheckLogFilter({
    this.skillName,
    this.levels = const {},
    this.dateRange,
  });

  bool get isEmpty =>
      skillName == null && levels.isEmpty && dateRange == null;

  /// 判定单条记录是否命中当前筛选条件。
  bool matches(SkillCheckRecord record) {
    if (skillName != null && record.skillName != skillName) return false;
    if (levels.isNotEmpty && !levels.contains(record.level)) return false;
    if (dateRange != null) {
      final t = record.createdAt;
      if (t.isBefore(dateRange!.start) || t.isAfter(dateRange!.end)) {
        return false;
      }
    }
    return true;
  }

  SkillCheckLogFilter copyWith({
    Object? skillName = _unset,
    Set<SkillCheckLevel>? levels,
    Object? dateRange = _unset,
  }) {
    return SkillCheckLogFilter(
      skillName:
          skillName == _unset ? this.skillName : skillName as String?,
      levels: levels ?? this.levels,
      dateRange:
          dateRange == _unset ? this.dateRange : dateRange as DateTimeRange?,
    );
  }

  Map<String, dynamic> toJson() => {
        'skillName': skillName,
        'levels': levels.map((l) => l.name).toList(),
        'dateRange': dateRange == null
            ? null
            : {
                'start': dateRange!.start.toIso8601String(),
                'end': dateRange!.end.toIso8601String(),
              },
      };

  static const Object _unset = Object();
}

/// 技能检定日志（[SkillCheckRecord]）的筛选 / 清理 / 导出控制器。
///
/// 设计要点：
/// - 直接持有当前 [Character]，筛选与导出都是运行时纯计算，不污染
///   `CharacterManager`，便于单元测试。
/// - 清理只删除命中筛选条件的日志，**不动**聚合统计 `skillGrowth`。
/// - 持久化通过注入的 [onPersist] 回调协调（页面传 `CharacterManager.
///   saveCurrentCharacter`），不新增 SharedPreferences key。
class SkillCheckLogController extends ChangeNotifier {
  final Character character;
  final Future<void> Function()? _onPersist;
  SkillCheckLogFilter _filter;

  SkillCheckLogController({
    required this.character,
    SkillCheckLogFilter filter = const SkillCheckLogFilter(),
    Future<void> Function()? onPersist,
  })  : _filter = filter,
        _onPersist = onPersist;

  SkillCheckLogFilter get filter => _filter;

  /// 全部日志条数（未筛选）。
  int get totalCount => character.skillCheckRecords.length;

  /// 命中当前筛选条件的日志，按时间倒序（最新在前）。
  List<SkillCheckRecord> get filteredRecords {
    final list =
        character.skillCheckRecords.where(_filter.matches).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void setFilter(SkillCheckLogFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void clearFilter() {
    _filter = const SkillCheckLogFilter();
    notifyListeners();
  }

  /// 删除命中筛选条件的检定日志，保留 `skillGrowth` 聚合统计。
  /// 返回被删除的条数；删除后自动 [persist]。
  Future<int> clearFiltered() async {
    final before = character.skillCheckRecords.length;
    character.skillCheckRecords.removeWhere(_filter.matches);
    final removed = before - character.skillCheckRecords.length;
    if (removed > 0) {
      await persist();
      notifyListeners();
    }
    return removed;
  }

  /// 导出当前筛选结果为 CSV 字符串（带 UTF-8 BOM，便于 Excel 正确显示中文）。
  /// 列顺序固定，转义按 RFC 4180。
  String exportCsv() {
    const header =
        'created_at,skill_name,skill_value,roll,level,final_success,'
        'luck_spent,luck_cost,rule_profile_id';
    final buffer = StringBuffer('\uFEFF')..writeln(header);
    for (final r in filteredRecords) {
      final row = [
        r.createdAt.toIso8601String(),
        r.skillName,
        '${r.skillValue}',
        '${r.roll}',
        r.level.name,
        '${r.finalSuccess}',
        '${r.luckSpent}',
        r.luckCost?.toString() ?? '',
        r.ruleProfileId,
      ].map(_csvEscape).join(',');
      buffer.writeln(row);
    }
    return buffer.toString();
  }

  /// 导出当前筛选结果 + **完整** `skillGrowth` 为 JSON 字符串。
  String exportJson() {
    final payload = {
      'schema': 'coccard.skill_check_log.v1',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'character': {
        'name': character.name,
        'id': character.id,
      },
      'filter': _filter.toJson(),
      'records': filteredRecords.map((r) => r.toJson()).toList(),
      'growth':
          character.skillGrowth.map((k, v) => MapEntry(k, v.toJson())),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// 协调持久化（删除日志后调用）。无注入回调时为 no-op，便于纯单测。
  Future<void> persist() async {
    final cb = _onPersist;
    if (cb != null) await cb();
  }

  /// RFC 4180：含逗号 / 双引号 / 换行的字段用双引号包裹，内部双引号转义为两个。
  static String _csvEscape(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
