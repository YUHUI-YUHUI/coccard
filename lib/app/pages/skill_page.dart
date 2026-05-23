import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/character_manager.dart';
import '../data/character.dart';
import '../data/coc_data.dart';
import '../data/skill.dart';

enum _SkillListFilter { occupation, added, recommended, all }

class SkillPage extends StatefulWidget {
  const SkillPage({super.key});

  @override
  State<SkillPage> createState() => _SkillPageState();
}

class _SkillPageState extends State<SkillPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('技能'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '本职'),
            Tab(text: '已加点'),
            Tab(text: '推荐未加'),
            Tab(text: '全部'),
          ],
        ),
      ),
      body: Consumer<CharacterManager>(
        builder: (context, manager, _) {
          return Column(
            children: [
              _buildPointDisplay(manager.character),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索技能...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSkillList(manager, _SkillListFilter.occupation),
                    _buildSkillList(manager, _SkillListFilter.added),
                    _buildSkillList(manager, _SkillListFilter.recommended),
                    _buildSkillList(manager, _SkillListFilter.all),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPointDisplay(Character character) {
    final occRemaining =
        character.occupationPoint - character.occupationPointSpent;
    final intRemaining = character.interestPoint - character.interestPointSpent;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '职业点数',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  '$occRemaining / ${character.occupationPoint}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: character.occupationPoint > 0
                      ? (character.occupationPointSpent / character.occupationPoint)
                      : 0,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                Text(
                  '兴趣点数',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                Text(
                  '$intRemaining / ${character.interestPoint}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: character.interestPoint > 0
                      ? (character.interestPointSpent / character.interestPoint)
                      : 0,
                  backgroundColor:
                      Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillList(CharacterManager manager, _SkillListFilter filter) {
    final character = manager.character;

    List<SkillDef> filteredSkills = SKILL_DEFS.where((skill) {
      if (!_matchesSearch(skill)) {
        return false;
      }

      switch (filter) {
        case _SkillListFilter.occupation:
          return _isOccupationSkill(character, skill);
        case _SkillListFilter.added:
          return _isSkillAdded(character, skill);
        case _SkillListFilter.recommended:
          return _isOccupationSkill(character, skill) &&
              !_isSkillAdded(character, skill);
        case _SkillListFilter.all:
          return true;
      }
    }).toList();

    if (filteredSkills.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _emptySkillText(character, filter),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredSkills.length,
      itemBuilder: (context, index) {
        final skill = filteredSkills[index];
        final skillValue = character.skills[skill.name] ?? skill.baseHalf;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(skill.name),
            subtitle: Text(_getCategoryName(skill.category)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$skillValue%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: skillValue > skill.baseHalf
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.casino),
                  onPressed: () =>
                      _rollSkillCheck(context, skill.name, skillValue),
                ),
              ],
            ),
            onTap: () =>
                _showSkillEditDialog(context, skill, skillValue, manager),
          ),
        );
      },
    );
  }

  bool _matchesSearch(SkillDef skill) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return skill.name.toLowerCase().contains(query) ||
        skill.key.toLowerCase().contains(query) ||
        _getCategoryName(skill.category).contains(query);
  }

  bool _isSkillAdded(Character character, SkillDef skill) {
    final currentValue = character.skills[skill.name] ?? skill.baseHalf;
    return currentValue > skill.baseHalf;
  }

  bool _isOccupationSkill(Character character, SkillDef skill) {
    final occupation = _selectedOccupation(character);
    if (occupation == null) {
      return false;
    }

    final skillText = occupation.sk;
    if (skillText.contains(skill.name) || skillText.contains(skill.key)) {
      return true;
    }

    final parenIndex = skill.name.indexOf('（');
    final skillRoot = parenIndex > 0
        ? skill.name.substring(0, parenIndex)
        : skill.name;
    if (skillRoot.length >= 2 && skillText.contains(skillRoot)) {
      return true;
    }

    if (skillText.contains('社交技能') &&
        skill.category == SkillCategory.social) {
      return true;
    }
    if (skillText.contains('格斗') &&
        skill.category == SkillCategory.combat) {
      return true;
    }
    if (skillText.contains('射击') &&
        skill.category == SkillCategory.shooting) {
      return true;
    }
    if ((skillText.contains('技艺') || skillText.contains('艺术')) &&
        (skill.name.startsWith('技艺') || skill.name == '艺术/手艺')) {
      return true;
    }
    if (skillText.contains('科学') && skill.name == '科学') {
      return true;
    }
    if (skillText.contains('驾驶') && skill.name.startsWith('驾驶')) {
      return true;
    }
    if (skillText.contains('汽车驾驶') && skill.name == '驾驶（汽车）') {
      return true;
    }
    if (skillText.contains('语言') &&
        (skill.name == '母语' || skill.name == '外语')) {
      return true;
    }
    if (skillText.contains('考古') && skill.name == '考古学') {
      return true;
    }

    return false;
  }

  Occupation? _selectedOccupation(Character character) {
    final selectedOccId = character.selectedOccId;
    if (selectedOccId == null) {
      return null;
    }

    for (final occupation in OCCUPATIONS) {
      if (occupation.id == selectedOccId) {
        return occupation;
      }
    }
    return null;
  }

  String _emptySkillText(Character character, _SkillListFilter filter) {
    if (_searchQuery.trim().isNotEmpty) {
      return '没有找到匹配的技能';
    }

    switch (filter) {
      case _SkillListFilter.occupation:
        return character.selectedOccId == null
            ? '先在角色页选择职业，之后这里会显示本职技能'
            : '当前职业没有匹配到本职技能';
      case _SkillListFilter.added:
        return '还没有加点的技能';
      case _SkillListFilter.recommended:
        return character.selectedOccId == null
            ? '先在角色页选择职业，之后这里会显示推荐但未加点的技能'
            : '本职技能都已经加过点了';
      case _SkillListFilter.all:
        return '没有技能';
    }
  }

  String _getCategoryName(SkillCategory category) {
    switch (category) {
      case SkillCategory.combat: return '格斗';
      case SkillCategory.shooting: return '射击';
      case SkillCategory.social: return '社交';
      case SkillCategory.academic: return '学术';
      case SkillCategory.stealth: return '隐秘';
      case SkillCategory.athletic: return '运动';
      case SkillCategory.perception: return '感知';
      case SkillCategory.knowledge: return '知识';
      case SkillCategory.craft: return '技艺';
      case SkillCategory.other: return '其他';
    }
  }

  void _showSkillEditDialog(BuildContext context, SkillDef skill, int currentValue, CharacterManager manager) {
    final character = manager.character;
    final occRemaining = character.occupationPoint - character.occupationPointSpent;
    final intRemaining = character.interestPoint - character.interestPointSpent;
    final occCtrl = TextEditingController();
    final intCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(skill.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前值: $currentValue%  (基础值: ${skill.baseHalf}%)'),
                const SizedBox(height: 16),
                const Text('分别投入职业点数和兴趣点数:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('职业点数: '),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: occCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          suffixText: "/$occRemaining",
                          isDense: true,
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('兴趣点数: '),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: intCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          suffixText: "/$intRemaining",
                          isDense: true,
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '将增加: ${((int.tryParse(occCtrl.text) ?? 0) + (int.tryParse(intCtrl.text) ?? 0))}%',
                  style: const TextStyle(color: Colors.blue),
                ),
                const SizedBox(height: 16),
                if (occRemaining == 0 && intRemaining == 0)
                  const Text('无可用点数', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final occAdd = int.tryParse(occCtrl.text) ?? 0;
                final intAdd = int.tryParse(intCtrl.text) ?? 0;

                if (occAdd > 0) {
                  final success = manager.addSkillPoints(skill.name, occAdd, true);
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('职业点数不足！')),
                    );
                    return;
                  }
                }
                if (intAdd > 0) {
                  final success = manager.addSkillPoints(skill.name, intAdd, false);
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('兴趣点数不足！')),
                    );
                    return;
                  }
                }
                Navigator.pop(context);
              },
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );
  }

  void _rollSkillCheck(BuildContext context, String skillName, int skillValue) {
    final random = Random();
    final roll = random.nextInt(100) + 1;
    final success = roll <= skillValue;
    final critical = roll <= skillValue / 20;
    final fumble = roll >= 96;

    String resultText;
    if (critical) {
      resultText = '大成功！';
    } else if (fumble) {
      resultText = '大失败！';
    } else if (success) {
      resultText = '成功';
    } else {
      resultText = '失败';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('技能检定: $skillName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$roll', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('技能值: $skillValue%', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Text(
              resultText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: success ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
