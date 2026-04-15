import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../data/character_manager.dart';
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
      body: Column(
        children: [
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
                _buildSkillList(context, SkillCategory.academic),
                _buildSkillList(context, SkillCategory.other),
                _buildSkillList(context, null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillList(BuildContext context, SkillCategory? filter) {
    final manager = Provider.of<CharacterManager>(context);
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
    final ctrl = TextEditingController(text: currentValue.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(skill.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('基础值: ${skill.baseHalf}%'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '技能值'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(ctrl.text) ?? skill.baseHalf;
              manager.updateSkill(skill.name, value);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
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
