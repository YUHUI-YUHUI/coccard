import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../data/character_manager.dart';
import '../data/character.dart';
import '../data/skill.dart';

class SkillPage extends StatefulWidget {
  const SkillPage({super.key});

  @override
  State<SkillPage> createState() => _SkillPageState();
}

class _SkillPageState extends State<SkillPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(text: '其他'),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                    _buildSkillList(manager, SkillCategory.academic),
                    _buildSkillList(manager, SkillCategory.other),
                    _buildSkillList(manager, null),
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
    final occRemaining = character.occupationPoint - character.occupationPointSpent;
    final intRemaining = character.interestPoint - character.interestPointSpent;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text('职业点数', style: TextStyle(fontSize: 12, color: Colors.blue)),
                Text(
                  '$occRemaining / ${character.occupationPoint}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: character.occupationPoint > 0
                      ? (character.occupationPointSpent / character.occupationPoint)
                      : 0,
                  backgroundColor: Colors.blue[100],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                const Text('兴趣点数', style: TextStyle(fontSize: 12, color: Colors.green)),
                Text(
                  '$intRemaining / ${character.interestPoint}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: character.interestPoint > 0
                      ? (character.interestPointSpent / character.interestPoint)
                      : 0,
                  backgroundColor: Colors.green[100],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillList(CharacterManager manager, SkillCategory? filter) {
    final character = manager.character;

    List<SkillDef> filteredSkills = SKILL_DEFS.where((skill) {
      if (_searchQuery.isNotEmpty) {
        return skill.name.contains(_searchQuery);
      }
      if (filter != null) {
        return skill.category == filter;
      }
      return true;
    }).toList();

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
                    color: skillValue >= skill.baseHalf ? Colors.green : Colors.grey,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.casino),
                  onPressed: () => _rollSkillCheck(context, skill.name, skillValue),
                ),
              ],
            ),
            onTap: () => _showSkillEditDialog(context, skill, skillValue, manager),
          ),
        );
      },
    );
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
            Text('技能值: $skillValue%', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Text(
              resultText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: success ? Colors.green : Colors.red,
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
