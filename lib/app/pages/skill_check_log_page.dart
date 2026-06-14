import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../data/character_manager.dart';
import '../data/check_rule.dart';
import '../data/skill_check_record.dart';
import '../setting/skill_check_log_controller.dart';

/// 时间筛选预设。
enum _TimePreset { all, today, days7, days30 }

extension _TimePresetLabel on _TimePreset {
  String get label {
    switch (this) {
      case _TimePreset.all:
        return '不限时间';
      case _TimePreset.today:
        return '今天';
      case _TimePreset.days7:
        return '最近 7 天';
      case _TimePreset.days30:
        return '最近 30 天';
    }
  }

  DateTimeRange? toRange() {
    final now = DateTime.now();
    switch (this) {
      case _TimePreset.all:
        return null;
      case _TimePreset.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
      case _TimePreset.days7:
        return DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
      case _TimePreset.days30:
        return DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
    }
  }
}

/// 技能检定日志页：筛选 / 清理 / 导出（提案 2026-06-12）。
class SkillCheckLogPage extends StatefulWidget {
  const SkillCheckLogPage({super.key});

  @override
  State<SkillCheckLogPage> createState() => _SkillCheckLogPageState();
}

class _SkillCheckLogPageState extends State<SkillCheckLogPage> {
  late final SkillCheckLogController _controller;
  bool _filterExpanded = true;

  String? _skillName;
  Set<SkillCheckLevel> _levels = {};
  _TimePreset _timePreset = _TimePreset.all;

  @override
  void initState() {
    super.initState();
    final manager = context.read<CharacterManager>();
    _controller = SkillCheckLogController(
      character: manager.character,
      onPersist: manager.saveCurrentCharacter,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyFilter() {
    _controller.setFilter(SkillCheckLogFilter(
      skillName: _skillName,
      levels: _levels,
      dateRange: _timePreset.toRange(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('技能检定日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            tooltip: '筛选',
            onPressed: () => setState(() => _filterExpanded = !_filterExpanded),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: '清理',
            onPressed: _confirmClear,
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: '导出',
            onPressed: _showExportMenu,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final records = _controller.filteredRecords;
          return Column(
            children: [
              if (_filterExpanded) _buildFilterBar(),
              _buildSummary(records.length),
              const Divider(height: 1),
              Expanded(
                child: records.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        itemCount: records.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) => _buildRow(records[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    final skillNames = _controller.character.skillCheckRecords
        .map((r) => r.skillName)
        .toSet()
        .toList()
      ..sort();

    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 48, child: Text('技能')),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _skillName,
                  hint: const Text('全部'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('全部'),
                    ),
                    ...skillNames.map((s) => DropdownMenuItem<String?>(
                          value: s,
                          child: Text(s),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() => _skillName = v);
                    _applyFilter();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 48, child: Text('等级')),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: SkillCheckLevel.values.map((level) {
                    final selected = _levels.contains(level);
                    return FilterChip(
                      label: Text(level.label, style: const TextStyle(fontSize: 12)),
                      selected: selected,
                      visualDensity: VisualDensity.compact,
                      onSelected: (on) {
                        setState(() {
                          if (on) {
                            _levels = {..._levels, level};
                          } else {
                            _levels = {..._levels}..remove(level);
                          }
                        });
                        _applyFilter();
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 48, child: Text('时间')),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<_TimePreset>(
                  isExpanded: true,
                  value: _timePreset,
                  items: _TimePreset.values
                      .map((p) => DropdownMenuItem<_TimePreset>(
                            value: p,
                            child: Text(p.label),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _timePreset = v);
                    _applyFilter();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(int filteredCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.history,
              size: 16, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 6),
          Text(
            '共 ${_controller.totalCount} 条，当前筛选 $filteredCount 条',
            style: TextStyle(
                fontSize: 13, color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        _controller.totalCount == 0 ? '暂无技能检定记录' : '没有符合筛选条件的记录',
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }

  Widget _buildRow(SkillCheckRecord r) {
    final color = _levelColor(r.level);
    return ListTile(
      dense: true,
      leading: Icon(Icons.circle, size: 12, color: color),
      title: Row(
        children: [
          Expanded(child: Text(r.skillName)),
          Text(_fmtDate(r.createdAt),
              style: TextStyle(
                  fontSize: 12, color: Theme.of(context).colorScheme.outline)),
        ],
      ),
      subtitle: Row(
        children: [
          Text('投 ${r.roll} / 目标 ${r.skillValue}',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Text(r.level.label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          if (r.luckSpent) ...[
            const SizedBox(width: 6),
            Text('幸运补正${r.luckCost != null ? ' -${r.luckCost}' : ''}',
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.tertiary)),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmClear() async {
    final count = _controller.filteredRecords.length;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前筛选没有可清理的记录')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清理检定日志'),
        content: Text('将删除匹配筛选条件的 $count 条日志，聚合统计（成长记录）不受影响，确认？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final removed = await _controller.clearFiltered();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已删除 $removed 条日志')),
    );
  }

  void _showExportMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('复制 CSV'),
              onTap: () {
                Navigator.pop(ctx);
                _copyToClipboard(_controller.exportCsv(), 'CSV');
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('复制 JSON'),
              onTap: () {
                Navigator.pop(ctx);
                _copyToClipboard(_controller.exportJson(), 'JSON');
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('保存到应用文档目录'),
              onTap: () {
                Navigator.pop(ctx);
                _saveToDocuments();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label 已复制到剪贴板')),
    );
  }

  Future<void> _saveToDocuments() async {
    final json = _controller.exportJson();
    String? path;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final file = File('${dir.path}/coccard_skill_log_$ts.json');
      await file.writeAsString(json);
      path = file.path;
    } catch (_) {
      path = null;
    }
    if (!mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('已保存'),
        content: SelectableText('文件位置：\n$path'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Color _levelColor(SkillCheckLevel level) {
    final scheme = Theme.of(context).colorScheme;
    switch (level) {
      case SkillCheckLevel.critical:
      case SkillCheckLevel.extreme:
        return Colors.green.shade700;
      case SkillCheckLevel.hard:
      case SkillCheckLevel.regular:
        return scheme.primary;
      case SkillCheckLevel.failure:
        return scheme.outline;
      case SkillCheckLevel.fumble:
        return scheme.error;
    }
  }

  static String _fmtDate(DateTime t) {
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}
