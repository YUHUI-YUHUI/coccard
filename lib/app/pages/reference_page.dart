import 'package:flutter/material.dart';
import 'dart:math';
import '../data/coc_data.dart';
import '../data/rule_knowledge.dart';

// 规则快查数据已迁移至 lib/app/data/rule_knowledge.dart

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
    final entries = ruleKnowledgeEntries
        .where((entry) => entry.matches(_ruleSearchQuery.trim(), _selectedRuleCategory))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              _buildRulebookCard(),
              const SizedBox(height: 12),
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
                  children: ruleCategories.map((category) {
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

  Widget _buildRulebookCard() {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf_outlined),
        title: const Text('守秘人规则书 PDF'),
        subtitle: const Text('应用内阅读'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushNamed(context, '/rulebook'),
      ),
    );
  }

  Widget _buildRuleCard(RuleKnowledgeEntry entry) {
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
    final durationRoll = _random.nextInt(10) + 1;
    String title;
    String text;
    String durationUnit;
    if (type == 'tmp') {
      final item = INSANITY_TMP[roll - 1];
      title = '即时症状 #$roll，持续 $durationRoll 轮';
      text = item.text;
      durationUnit = '轮';
    } else {
      final item = INSANITY_LONG[roll - 1];
      title = '长期症状 #$roll，持续 $durationRoll 小时';
      text = item.text;
      durationUnit = '小时';
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [const Icon(Icons.psychology, color: Colors.purple), const SizedBox(width: 8), Text(title)]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(children: [
              const Icon(Icons.casino, size: 18, color: Colors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '本次投出：症状 #$roll · 持续 $durationRoll $durationUnit',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.purple),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const Text('⚠️ 理智值可能下降', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ]),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('确定'))],
      ),
    );
  }
}
