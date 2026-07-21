import 'package:flutter/material.dart';

import '../data/character.dart';
import '../data/character_manager.dart';
import '../data/skill.dart';
import 'skill_check_dialog.dart';

class QuickSkillCard extends StatelessWidget {
  const QuickSkillCard({
    super.key,
    required this.character,
    required this.manager,
  });

  final Character character;
  final CharacterManager manager;

  @override
  Widget build(BuildContext context) {
    final quickSkills =
        character.quickSkills.where((name) => name.trim().isNotEmpty).toList();

    return Card(
      key: const Key('quick_skill_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '快捷检定',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  key: const Key('configure_quick_skills'),
                  tooltip: '选择快捷技能',
                  icon: const Icon(Icons.tune),
                  onPressed: () => _showSkillPicker(context),
                ),
              ],
            ),
            const Divider(),
            if (quickSkills.isEmpty) ...[
              Text(
                '选择跑团中常用的技能，之后可在首页直接检定。',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('choose_quick_skills'),
                onPressed: () => _showSkillPicker(context),
                icon: const Icon(Icons.add),
                label: const Text('选择快捷技能'),
              ),
            ] else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickSkills.map((skillName) {
                  final skillValue = _skillValue(skillName);
                  return ActionChip(
                    key: ValueKey('quick_skill_$skillName'),
                    avatar: const Icon(Icons.casino_outlined, size: 18),
                    label: Text('$skillName $skillValue%'),
                    tooltip: '点击进行 $skillName 检定',
                    onPressed: () => showSkillCheckDialog(
                      context: context,
                      manager: manager,
                      skillName: skillName,
                      skillValue: skillValue,
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  int _skillValue(String skillName) {
    return character.skills[skillName] ?? getSkillDef(skillName)?.baseHalf ?? 0;
  }

  void _showSkillPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _QuickSkillPicker(
        character: character,
        initialSelection: character.quickSkills,
        onSave: (selection) async {
          await manager.setQuickSkills(selection);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
  }
}

class _QuickSkillPicker extends StatefulWidget {
  const _QuickSkillPicker({
    required this.character,
    required this.initialSelection,
    required this.onSave,
  });

  final Character character;
  final List<String> initialSelection;
  final Future<void> Function(List<String>) onSave;

  @override
  State<_QuickSkillPicker> createState() => _QuickSkillPickerState();
}

class _QuickSkillPickerState extends State<_QuickSkillPicker> {
  final TextEditingController _searchController = TextEditingController();
  late final List<String> _selected;
  late final List<String> _allSkills;
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection.toSet().toList();
    final standard = SKILL_DEFS.map((skill) => skill.name).toList();
    final extras = <String>{
      ...widget.character.skills.keys,
      ...widget.initialSelection,
    }.where((name) => !standard.contains(name)).toList()
      ..sort();
    _allSkills = [...standard, ...extras];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final visibleSkills = query.isEmpty
        ? _allSkills
        : _allSkills
            .where((name) => name.toLowerCase().contains(query))
            .toList();

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '选择快捷技能',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${_selected.length}/${CharacterManager.maxQuickSkills}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const Key('quick_skill_search'),
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '搜索技能',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: visibleSkills.isEmpty
                ? const Center(child: Text('没有找到匹配的技能'))
                : ListView.builder(
                    itemCount: visibleSkills.length,
                    itemBuilder: (context, index) {
                      final skillName = visibleSkills[index];
                      final selected = _selected.contains(skillName);
                      final value = widget.character.skills[skillName] ??
                          getSkillDef(skillName)?.baseHalf ??
                          0;
                      return CheckboxListTile(
                        key: ValueKey('quick_skill_option_$skillName'),
                        value: selected,
                        title: Text(skillName),
                        subtitle: Text('当前值 $value%'),
                        onChanged: (_) => _toggleSkill(skillName),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                TextButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => setState(_selected.clear),
                  child: const Text('清空'),
                ),
                const Spacer(),
                FilledButton(
                  key: const Key('save_quick_skills'),
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? '保存中…' : '保存'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSkill(String skillName) {
    setState(() {
      if (_selected.remove(skillName)) return;
      if (_selected.length >= CharacterManager.maxQuickSkills) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('首页最多显示 8 个快捷技能')),
        );
        return;
      }
      _selected.add(skillName);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(_selected);
    if (mounted) setState(() => _saving = false);
  }
}
