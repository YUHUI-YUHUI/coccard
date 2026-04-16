import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/character_manager.dart';
import '../data/character.dart';
import '../widgets/attribute_widget.dart';
import '../widgets/derived_stats_widget.dart';
import '../widgets/dice_roller.dart';
import '../widgets/app_drawer_widget.dart';
import '../data/coc_data.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<CharacterManager>(
          builder: (context, manager, _) {
            return Text(manager.character.name.isEmpty
                ? '新角色'
                : manager.character.name);
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() => _isEditMode = !_isEditMode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isEditMode ? '已进入编辑模式' : '已退出编辑模式')),
              );
            },
            tooltip: '编辑模式',
          ),
          IconButton(
            icon: const Icon(Icons.casino_outlined),
            onPressed: _isEditMode ? () => _showDiceRoller(context) : null,
            tooltip: '投骰子',
          ),
        ],
      ),
      drawer: const AppDrawerWidget(),
      body: Consumer<CharacterManager>(
        builder: (context, manager, _) {
          final character = manager.character;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoCard(context, character, manager),
                const SizedBox(height: 16),
                _buildAttributeCard(context, character, manager),
                const SizedBox(height: 16),
                _buildDerivedStatsCard(context, manager.character, manager),
                const SizedBox(height: 16),
                _buildWeaponsCard(context, character),
                const SizedBox(height: 16),
                _buildFinanceCard(context, character, manager),
                const SizedBox(height: 16),
                _buildBackstoryCard(context, character, manager),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicInfoCard(BuildContext context, Character character, CharacterManager manager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('基本信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showBasicInfoDialog(context, character, manager),
                ),
              ],
            ),
            const Divider(),
            _infoRow('玩家', character.player),
            _infoRow('职业', character.occupation.isEmpty ? '未选择' : character.occupation),
            _infoRow('年龄', character.age),
            _infoRow('性别', character.gender),
            _infoRow('居住地', character.residence),
            _infoRow('出生地', character.birthplace),
            const SizedBox(height: 8),
            if (character.selectedOccId == null)
              ElevatedButton(
                onPressed: () => _showOccupationPicker(context, manager),
                child: const Text('选择职业'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAttributeCard(BuildContext context, Character character, CharacterManager manager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('属性', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (_isEditMode) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.casino, color: Colors.purple, size: 20),
                        onPressed: () {
                          manager.rollAttributes();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已随机生成属性 (3D6×5)')),
                          );
                        },
                        tooltip: '随机属性',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
                if (_isEditMode)
                  const Icon(Icons.edit, color: Colors.green, size: 16),
              ],
            ),
            const Divider(),
            AttributeWidget(
              attributes: {
                '力量': character.str,
                '体质': character.con,
                '体型': character.siz,
                '敏捷': character.dex,
                '外貌': character.app,
                '智力': character.int_,
                '意志': character.pow,
                '教育': character.edu,
              },
              onEdit: (attr, value) => manager.updateAttribute(attr, value),
              isEditable: _isEditMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDerivedStatsCard(BuildContext context, Character character, CharacterManager manager) {
    final occRemaining = character.occupationPoint - character.occupationPointSpent;
    final intRemaining = character.interestPoint - character.interestPointSpent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('衍生属性', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            DerivedStatsWidget(
              hp: '${character.currentHp}/${character.maxHp}',
              mp: '${character.currentMp}/${character.maxMp}',
              sanity: '${character.sanity}/${character.maxSanity}',
              luck: '${character.luckDice} (${character.luck})',
              move: character.move.toString(),
              bodyBuild: character.build.toString(),
              damageBonus: character.damageBonus,
            ),
            const SizedBox(height: 8),
            const Divider(),
            const Text('技能点数', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('职业点数', style: TextStyle(color: Colors.blue)),
                    Text(
                      '$occRemaining / ${character.occupationPoint}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('兴趣点数', style: TextStyle(color: Colors.green)),
                    Text(
                      '$intRemaining / ${character.interestPoint}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('信誉范围', style: TextStyle(color: Colors.orange)),
                    Text(
                      '${character.creditMin}-${character.creditMax}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeaponsCard(BuildContext context, Character character) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('武器', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/weapons'),
                  child: const Text('管理'),
                ),
              ],
            ),
            const Divider(),
            if (character.weapons.isEmpty)
              const Text('暂无武器', style: TextStyle(color: Colors.grey))
            else
              ...character.weapons.take(3).map((w) => ListTile(
                dense: true,
                title: Text(w.name),
                subtitle: Text('技能 ${w.skill}% | 伤害 ${w.damage}'),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceCard(BuildContext context, Character character, CharacterManager manager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('财务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showFinanceDialog(context, character, manager),
                ),
              ],
            ),
            const Divider(),
            _infoRow('现金', '${character.cash}'),
            _infoRow('每月花费', '${character.spending}'),
            _infoRow('财产', '${character.assets}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBackstoryCard(BuildContext context, Character character, CharacterManager manager) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('背景故事', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showBackstoryDialog(context, character, manager),
                ),
              ],
            ),
            const Divider(),
            Text(character.backstory.isEmpty ? '暂无背景故事' : character.backstory),
          ],
        ),
      ),
    );
  }

  void _showBasicInfoDialog(BuildContext context, Character character, CharacterManager manager) {
    final nameCtrl = TextEditingController(text: character.name);
    final playerCtrl = TextEditingController(text: character.player);
    final ageCtrl = TextEditingController(text: character.age);
    final genderCtrl = TextEditingController(text: character.gender);
    final residenceCtrl = TextEditingController(text: character.residence);
    final birthplaceCtrl = TextEditingController(text: character.birthplace);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑基本信息'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '角色名')),
              TextField(controller: playerCtrl, decoration: const InputDecoration(labelText: '玩家')),
              TextField(controller: ageCtrl, decoration: const InputDecoration(labelText: '年龄')),
              TextField(controller: genderCtrl, decoration: const InputDecoration(labelText: '性别')),
              TextField(controller: residenceCtrl, decoration: const InputDecoration(labelText: '居住地')),
              TextField(controller: birthplaceCtrl, decoration: const InputDecoration(labelText: '出生地')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              manager.updateBasicInfo(
                name: nameCtrl.text,
                player: playerCtrl.text,
                age: ageCtrl.text,
                gender: genderCtrl.text,
                residence: residenceCtrl.text,
                birthplace: birthplaceCtrl.text,
              );
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showOccupationPicker(BuildContext context, CharacterManager manager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text('选择职业', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: OCCUPATIONS.length,
                  itemBuilder: (context, index) {
                    final occ = OCCUPATIONS[index];
                    return ListTile(
                      title: Text(occ.n),
                      subtitle: Text('信用: ${occ.min}-${occ.max}'),
                      onTap: () {
                        manager.applyOccupation(occ);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('已选择职业: ${occ.n}')),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFinanceDialog(BuildContext context, Character character, CharacterManager manager) {
    final cashCtrl = TextEditingController(text: character.cash.toString());
    final spendingCtrl = TextEditingController(text: character.spending.toString());
    final assetsCtrl = TextEditingController(text: character.assets.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑财务'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cashCtrl, decoration: const InputDecoration(labelText: '现金'), keyboardType: TextInputType.number),
            TextField(controller: spendingCtrl, decoration: const InputDecoration(labelText: '每月花费'), keyboardType: TextInputType.number),
            TextField(controller: assetsCtrl, decoration: const InputDecoration(labelText: '财产'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              manager.updateFinance(
                cash: int.tryParse(cashCtrl.text) ?? 0,
                spending: int.tryParse(spendingCtrl.text) ?? 0,
                assets: int.tryParse(assetsCtrl.text) ?? 0,
              );
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showBackstoryDialog(BuildContext context, Character character, CharacterManager manager) {
    final backstoryCtrl = TextEditingController(text: character.backstory);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑背景故事'),
        content: TextField(controller: backstoryCtrl, maxLines: 5, decoration: const InputDecoration(labelText: '背景故事')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              manager.updateBackstory(backstoryCtrl.text);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDiceRoller(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        content: DiceRollerWidget(),
      ),
    );
  }
}
