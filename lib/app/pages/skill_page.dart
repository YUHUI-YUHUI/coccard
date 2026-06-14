import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/character_manager.dart';
import '../data/character.dart';
import '../data/check_rule.dart';
import '../data/coc_data.dart';
import '../data/skill.dart';
import '../data/skill_check_record.dart';
import '../setting/check_rule_controller.dart';

enum _SkillListFilter { occupation, added, recommended, all }

const D100CheckEvaluator _evaluator = D100CheckEvaluator();

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
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '检定日志',
            onPressed: () =>
                Navigator.pushNamed(context, '/skill_check_log'),
          ),
          Consumer<CharacterManager>(
            builder: (context, manager, _) {
              final markedCount = manager
                  .markedGrowthSkills()
                  .length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.auto_awesome),
                    tooltip: markedCount > 0
                        ? '幕间成长（$markedCount 项待检）'
                        : '幕间成长',
                    onPressed: () =>
                        Navigator.pushNamed(context, '/skill_growth'),
                  ),
                  if (markedCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$markedCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
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
        final growth = manager.character.skillGrowth[skill.name];
        final hasStats = growth != null &&
            (growth.successCount > 0 ||
                growth.failureCount > 0 ||
                growth.growthMarked);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(skill.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_getCategoryName(skill.category)),
                if (hasStats) _buildGrowthLine(growth, context),
              ],
            ),
            isThreeLine: hasStats,
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
                  tooltip: '一键检定',
                  onPressed: () =>
                      _rollSkillCheck(context, manager, skill.name, skillValue),
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

  Widget _buildGrowthLine(SkillGrowthState growth, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final successColor = scheme.tertiary;
    final failureColor = scheme.error;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _statChip(
            icon: Icons.check_circle_outline,
            label: '成功 ${growth.successCount}',
            color: successColor,
          ),
          _statChip(
            icon: Icons.cancel_outlined,
            label: '失败 ${growth.failureCount}',
            color: failureColor,
          ),
          if (growth.growthMarked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                  SizedBox(width: 2),
                  Text(
                    '成长待检',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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

  void _rollSkillCheck(
    BuildContext context,
    CharacterManager manager,
    String skillName,
    int skillValue,
  ) {
    final random = Random();
    final roll = random.nextInt(100) + 1;
    final rule = context.read<CheckRuleController>().profile;
    final result = _evaluator.evaluate(
      target: skillValue,
      roll: roll,
      rule: rule,
    );
    manager.recordSkillCheck(result, skillName);

    final luckCost = result.luckCost;
    final currentLuck = manager.character.luck;
    final canSpendLuck = rule.allowSpendLuck &&
        result.canUseLuck &&
        luckCost > 0 &&
        luckCost <= currentLuck;
    final resultColor = result.isSuccess
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.error;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$skillName 检定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${result.roll}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: resultColor,
              ),
            ),
            Text(
              result.resultText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: resultColor,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _checkInfoChip('目标', '${result.skillValue}%'),
                _checkInfoChip('困难', '${result.hardValue}%'),
                _checkInfoChip('极难', '${result.extremeValue}%'),
                _checkInfoChip('当前幸运', '$currentLuck'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '规则：${rule.name}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (!result.isSuccess) ...[
              const SizedBox(height: 16),
              Text(
                _luckHintText(result, currentLuck, rule),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (canSpendLuck)
            TextButton.icon(
              onPressed: () {
                final spent = manager.spendLuck(luckCost);
                if (spent) {
                  manager.markLastCheckLuckSpent(
                    skillName: skillName,
                    luckCost: luckCost,
                  );
                }
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      spent
                          ? '已花费 $luckCost 幸运，补成普通成功'
                          : '幸运不足，无法补正',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.star),
              label: Text('花费 $luckCost 幸运'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _checkInfoChip(String label, String value) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text('$label $value'),
    );
  }

  String _luckHintText(
    SkillCheckResult result,
    int currentLuck,
    CheckRuleProfile rule,
  ) {
    if (result.level == SkillCheckLevel.fumble) {
      return '大失败不能通过花费幸运补正';
    }
    if (!rule.allowSpendLuck) {
      return '当前规则禁用幸运补正';
    }

    final cost = result.luckCost;
    if (cost <= 0) {
      return '';
    }

    if (cost <= currentLuck) {
      return '可花费 $cost 点幸运，将结果补成普通成功';
    }
    return '需要 $cost 点幸运才能补成普通成功，当前幸运不足';
  }
}
