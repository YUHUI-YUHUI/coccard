import 'package:flutter/material.dart';
import 'dart:math';
import '../data/coc_data.dart';

class _RuleQuickEntry {
  final String category;
  final String title;
  final String summary;
  final List<String> bullets;
  final List<String> tags;

  const _RuleQuickEntry({
    required this.category,
    required this.title,
    required this.summary,
    required this.bullets,
    this.tags = const [],
  });

  bool matches(String query, String categoryFilter) {
    final matchesCategory =
        categoryFilter == '全部' || category == categoryFilter;
    if (!matchesCategory) return false;
    if (query.isEmpty) return true;

    final text = [
      category,
      title,
      summary,
      ...bullets,
      ...tags,
    ].join(' ').toLowerCase();
    return text.contains(query.toLowerCase());
  }
}

const _ruleCategories = ['全部', '检定', '骰子', '理智', '战斗', '成长'];

const _ruleQuickEntries = [
  _RuleQuickEntry(
    category: '检定',
    title: 'D100 检定与成功等级',
    summary: '掷 1D100，结果小于等于目标值为成功；再按半值和五分值判断成功等级。',
    bullets: [
      '普通成功：小于等于目标值；困难成功：小于等于目标值的一半。',
      '极难成功：小于等于目标值的五分之一；大成功通常为 1。',
      '大失败：目标值低于 50 时为 96-100；目标值 50 或以上时为 100。',
    ],
    tags: ['普通成功', '困难成功', '极难成功', '大成功', '大失败'],
  ),
  _RuleQuickEntry(
    category: '骰子',
    title: '奖励骰与惩罚骰',
    summary: '奖励骰或惩罚骰会额外投十位骰，个位骰保持同一个。',
    bullets: [
      '奖励骰取更有利的十位结果，惩罚骰取更不利的十位结果。',
      '多个奖励/惩罚可以相互抵消，抵消后只处理剩余的奖励或惩罚。',
      '先确定奖励/惩罚数量，再投骰，方便桌面上所有人对结果有共识。',
    ],
    tags: ['奖励骰', '惩罚骰', '十位骰'],
  ),
  _RuleQuickEntry(
    category: '检定',
    title: 'Push Roll',
    summary: '失败后，玩家说明新的做法或承担额外风险，可以请求重掷一次。',
    bullets: [
      'Push 不是简单重投，必须改变方法、投入更多资源，或让风险升级。',
      'Push 再失败时，后果应明显更严重，通常由守秘人提前讲清方向。',
      '战斗、理智损失、伤害等场景通常不默认允许 Push，以守秘人裁定为准。',
    ],
    tags: ['重掷', '孤注一掷', '失败后果'],
  ),
  _RuleQuickEntry(
    category: '检定',
    title: '对抗检定',
    summary: '双方分别检定，先比较成功等级；成功等级相同再比较相关技能或属性值。',
    bullets: [
      '成功等级更高的一方胜出；双方都失败时，通常维持僵局或由守秘人推进后果。',
      '成功等级相同，通常由基础值更高的一方胜出；仍相同则可视为平局。',
      '近战里的反击和闪避有专门判定习惯，查战斗条目更稳。',
    ],
    tags: ['对抗', '成功等级', '平局'],
  ),
  _RuleQuickEntry(
    category: '检定',
    title: '幸运检定与花费幸运',
    summary: '幸运检定以当前幸运值为目标；是否允许花费幸运由本桌规则决定。',
    bullets: [
      '幸运检定失败时，如果本桌允许花费幸运，可按差值扣减幸运来补足成功。',
      '幸运通常不能解决所有失败，尤其是伤害、理智、成长等关键流程。',
      '花费后的幸运值会影响后续幸运检定，适合留给真正要命的瞬间。',
    ],
    tags: ['幸运', '花费幸运', 'Luck'],
  ),
  _RuleQuickEntry(
    category: '理智',
    title: '理智损失与临时疯狂',
    summary: '遭遇恐怖时按事件结算 SAN 损失；单次损失 5 点或更多时可能触发临时疯狂。',
    bullets: [
      '单次损失 5 点或更多时，进行 INT 检定；成功代表理解冲击并陷入临时疯狂。',
      '临时疯狂可使用即时症状，通常持续 1D10 轮。',
      '检定失败可理解为大脑暂时屏蔽了冲击，但 SAN 损失仍然发生。',
    ],
    tags: ['SAN', '临时疯狂', 'INT'],
  ),
  _RuleQuickEntry(
    category: '理智',
    title: '不定疯狂与疯狂发作',
    summary: '短时间内损失大量理智时可能进入不定疯狂，并用总结症状表现失控阶段。',
    bullets: [
      '一天内累计损失达到当前理智的五分之一时，通常触发不定疯狂。',
      '总结症状常用于处理失控后的空白期，通常覆盖 1D10 小时。',
      '疯狂后可为角色添加恐惧症、躁狂症、妄想或背景变化。',
    ],
    tags: ['不定疯狂', '总结症状', '恐惧症', '躁狂症'],
  ),
  _RuleQuickEntry(
    category: '战斗',
    title: '战斗轮与行动顺序',
    summary: '战斗通常按 DEX 从高到低行动；一轮里处理移动、攻击、施法或其他行动。',
    bullets: [
      '同 DEX 时可比较相关能力或由守秘人裁定先后。',
      '已经在本轮反击或闪避过的目标，面对额外近战攻击时通常更吃亏。',
      '复杂动作可以拆成多轮处理，先讲清目标、代价和可能的检定。',
    ],
    tags: ['DEX', '行动', '轮次'],
  ),
  _RuleQuickEntry(
    category: '战斗',
    title: '近战：反击与闪避',
    summary: '受到近战攻击时，目标通常可以选择反击或闪避。',
    bullets: [
      '选择反击时，攻击方在同等级成功下通常占优；防守方需要更高成功等级才能反制。',
      '选择闪避时，防守方达到同等级成功通常即可避开攻击。',
      '以寡敌众、倒地、受限空间、黑暗等情况可转化为奖励骰或惩罚骰。',
    ],
    tags: ['近战', '反击', '闪避', '斗殴'],
  ),
  _RuleQuickEntry(
    category: '战斗',
    title: '火器与故障',
    summary: '火器攻击一般不能被反击；目标可尝试寻找掩护或规避射线。',
    bullets: [
      '近距离、瞄准、连射、掩护、黑暗等因素通常转化为奖励骰或惩罚骰。',
      '投骰结果达到武器故障值时，武器卡壳或失效，需按场景处理。',
      '射击进近战、穿透、装弹和弹药消耗建议当场写清，避免回合后倒账。',
    ],
    tags: ['射击', '故障', '掩护', '装弹'],
  ),
  _RuleQuickEntry(
    category: '战斗',
    title: '伤害、重大伤口与治疗',
    summary: '生命值降为 0 会失去行动能力；单次伤害达到最大 HP 一半或更多时会造成重大伤口。',
    bullets: [
      '有重大伤口且 HP 降到 0 时进入濒死流程，需要及时急救或医学处理。',
      '急救通常恢复 1 HP；医学治疗通常恢复更多，但耗时也更长。',
      '无重大伤口时自然恢复较快；有重大伤口时恢复取决于后续治疗和体质检定。',
    ],
    tags: ['HP', '重大伤口', '濒死', '急救', '医学'],
  ),
  _RuleQuickEntry(
    category: '成长',
    title: '幕间成长检定',
    summary: '成功使用过的技能可做成长标记，幕间通过成长检定决定是否提升。',
    bullets: [
      '成长检定通常要掷出高于当前技能值，代表仍有提升空间。',
      '成长成功后增加 1D10 点，并清除该技能的成长标记。',
      '很高的技能仍有成长机会，但提升会更稀少，适合在幕间统一处理。',
    ],
    tags: ['技能成长', '幕间', '1D10'],
  ),
  _RuleQuickEntry(
    category: '检定',
    title: '常用衍生数值',
    summary: '建卡或临时核对时，优先检查 HP、MP、SAN、移动率、DB 与体格是否一致。',
    bullets: [
      'HP 通常由体质和体型决定；MP 通常由意志决定；SAN 初始通常跟意志相关。',
      '移动率要比较力量、敏捷和体型，并考虑年龄修正。',
      '伤害加值与体格由力量加体型的合计区间决定。',
    ],
    tags: ['HP', 'MP', 'SAN', 'MOV', 'DB', '体格'],
  ),
];

class ReferencePage extends StatefulWidget {
  const ReferencePage({super.key});

  @override
  State<ReferencePage> createState() => _ReferencePageState();
}

class _ReferencePageState extends State<ReferencePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Random _random = Random();
  final TextEditingController _ruleSearchCtrl = TextEditingController();
  String _ruleSearchQuery = '';
  String _selectedRuleCategory = '全部';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ruleSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('参考表'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '规则快查'),
            Tab(text: '疯狂发作'),
            Tab(text: '恐惧症'),
            Tab(text: '躁狂症'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRulesTab(),
          _buildInsanityTab(),
          _buildPhobiasTab(),
          _buildManiasTab(),
        ],
      ),
    );
  }

  Widget _buildRulesTab() {
    final entries = _ruleQuickEntries
        .where((entry) => entry.matches(_ruleSearchQuery.trim(), _selectedRuleCategory))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _ruleSearchCtrl,
                decoration: InputDecoration(
                  hintText: '搜索检定、疯狂、战斗...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  suffixIcon: _ruleSearchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _ruleSearchCtrl.clear();
                            setState(() => _ruleSearchQuery = '');
                          },
                        ),
                ),
                onChanged: (value) => setState(() => _ruleSearchQuery = value),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _ruleCategories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _selectedRuleCategory == category,
                        onSelected: (_) {
                          setState(() => _selectedRuleCategory = category);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    '没有找到匹配的规则',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) => _buildRuleCard(entries[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(_RuleQuickEntry entry) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    _ruleCategoryIcon(entry.category),
                    size: 18,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.category,
                        style: TextStyle(color: colorScheme.primary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(entry.summary),
            const SizedBox(height: 8),
            ...entry.bullets.map((bullet) {
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: Text(bullet)),
                  ],
                ),
              );
            }),
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: entry.tags.take(5).map((tag) {
                  return Chip(
                    label: Text(tag),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _ruleCategoryIcon(String category) {
    switch (category) {
      case '骰子':
        return Icons.casino_outlined;
      case '理智':
        return Icons.psychology_outlined;
      case '战斗':
        return Icons.gpp_maybe_outlined;
      case '成长':
        return Icons.trending_up;
      case '检定':
      default:
        return Icons.rule_outlined;
    }
  }

  Widget _buildInsanityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.purple.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('🎲 随机触发疯狂', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _rollInsanity('tmp'),
                        icon: const Icon(Icons.bolt),
                        label: const Text('即时症状'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _rollInsanity('long'),
                        icon: const Icon(Icons.hourglass_bottom),
                        label: const Text('长期症状'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('即时症状（1D10轮后消失）', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: INSANITY_TMP.map((item) => ListTile(
                leading: CircleAvatar(backgroundColor: Colors.purple, child: Text('${item.id}', style: const TextStyle(color: Colors.white))),
                title: Text(item.text),
              )).toList(),
            ),
          ),
          const SizedBox(height: 24),
          const Text('长期症状（1D10小时后恢复）', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: INSANITY_LONG.map((item) => ListTile(
                leading: CircleAvatar(backgroundColor: Colors.deepPurple, child: Text('${item.id}', style: const TextStyle(color: Colors.white))),
                title: Text(item.text),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhobiasTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: PHOBIAS.length,
      itemBuilder: (context, index) {
        final parts = PHOBIAS[index].split('：');
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.orange, child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),
            title: Text(parts[0]),
            subtitle: parts.length > 1 ? Text(parts[1]) : null,
          ),
        );
      },
    );
  }

  Widget _buildManiasTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: MANIAS.length,
      itemBuilder: (context, index) {
        final parts = MANIAS[index].split('：');
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.teal, child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),
            title: Text(parts[0]),
            subtitle: parts.length > 1 ? Text(parts[1]) : null,
          ),
        );
      },
    );
  }

  void _rollInsanity(String type) {
    final roll = _random.nextInt(10) + 1;
    String title;
    String text;
    if (type == 'tmp') {
      final item = INSANITY_TMP[roll - 1];
      title = '即时症状 #$roll';
      text = item.text;
    } else {
      final item = INSANITY_LONG[roll - 1];
      title = '长期症状 #$roll';
      text = item.text;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [const Icon(Icons.psychology, color: Colors.purple), const SizedBox(width: 8), Text(title)]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          const Text('⚠️ 理智值可能下降', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ]),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('确定'))],
      ),
    );
  }
}
