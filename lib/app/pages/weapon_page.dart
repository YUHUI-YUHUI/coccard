import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/character_manager.dart';
import '../data/character.dart';

class WeaponPage extends StatelessWidget {
  const WeaponPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('武器管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_add),
            onPressed: () => _showWeaponReference(context),
            tooltip: '武器库',
          ),
        ],
      ),
      body: Consumer<CharacterManager>(
        builder: (context, manager, _) {
          final weapons = manager.character.weapons;

          if (weapons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无武器'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showWeaponReference(context),
                    icon: const Icon(Icons.library_add),
                    label: const Text('从武器库添加'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: weapons.length,
            itemBuilder: (context, index) {
              final weapon = weapons[index];
              return _WeaponCard(
                weapon: weapon,
                onEdit: () => _showEditWeaponDialog(context, index, weapon, manager),
                onDelete: () => _confirmDelete(context, index, manager),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWeaponDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showWeaponReference(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return _WeaponReferenceList(scrollController: scrollController);
        },
      ),
    );
  }

  void _showAddWeaponDialog(BuildContext context) {
    final manager = Provider.of<CharacterManager>(context, listen: false);
    final nameCtrl = TextEditingController();
    final skillCtrl = TextEditingController(text: '25');
    final damageCtrl = TextEditingController();
    final rangeCtrl = TextEditingController();
    final attacksCtrl = TextEditingController(text: '1');
    final ammoCtrl = TextEditingController(text: '—');
    final malfunctionCtrl = TextEditingController(text: '—');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加武器'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '武器名称')),
              TextField(controller: skillCtrl, decoration: const InputDecoration(labelText: '技能%'), keyboardType: TextInputType.number),
              TextField(controller: damageCtrl, decoration: const InputDecoration(labelText: '伤害')),
              TextField(controller: rangeCtrl, decoration: const InputDecoration(labelText: '射程')),
              TextField(controller: attacksCtrl, decoration: const InputDecoration(labelText: '攻击次数')),
              TextField(controller: ammoCtrl, decoration: const InputDecoration(labelText: '弹药')),
              TextField(controller: malfunctionCtrl, decoration: const InputDecoration(labelText: '故障')),
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
              manager.addWeapon(CharacterWeapon()
                ..name = nameCtrl.text
                ..skill = int.tryParse(skillCtrl.text) ?? 25
                ..damage = damageCtrl.text
                ..range = rangeCtrl.text
                ..attacks = attacksCtrl.text
                ..ammo = ammoCtrl.text
                ..malfunction = malfunctionCtrl.text);
              Navigator.pop(context);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditWeaponDialog(BuildContext context, int index, CharacterWeapon weapon, CharacterManager manager) {
    final nameCtrl = TextEditingController(text: weapon.name);
    final skillCtrl = TextEditingController(text: weapon.skill.toString());
    final damageCtrl = TextEditingController(text: weapon.damage);
    final rangeCtrl = TextEditingController(text: weapon.range);
    final attacksCtrl = TextEditingController(text: weapon.attacks);
    final ammoCtrl = TextEditingController(text: weapon.ammo);
    final malfunctionCtrl = TextEditingController(text: weapon.malfunction);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑武器'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '武器名称')),
              TextField(controller: skillCtrl, decoration: const InputDecoration(labelText: '技能%'), keyboardType: TextInputType.number),
              TextField(controller: damageCtrl, decoration: const InputDecoration(labelText: '伤害')),
              TextField(controller: rangeCtrl, decoration: const InputDecoration(labelText: '射程')),
              TextField(controller: attacksCtrl, decoration: const InputDecoration(labelText: '攻击次数')),
              TextField(controller: ammoCtrl, decoration: const InputDecoration(labelText: '弹药')),
              TextField(controller: malfunctionCtrl, decoration: const InputDecoration(labelText: '故障')),
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
              manager.updateWeapon(index, CharacterWeapon()
                ..name = nameCtrl.text
                ..skill = int.tryParse(skillCtrl.text) ?? 25
                ..damage = damageCtrl.text
                ..range = rangeCtrl.text
                ..attacks = attacksCtrl.text
                ..ammo = ammoCtrl.text
                ..malfunction = malfunctionCtrl.text);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index, CharacterManager manager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这件武器吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              manager.deleteWeapon(index);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _WeaponCard extends StatelessWidget {
  final CharacterWeapon weapon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WeaponCard({
    required this.weapon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  weapon.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
                  ],
                ),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _statChip('技能', '${weapon.skill}%'),
                _statChip('伤害', weapon.damage),
                _statChip('射程', weapon.range),
                _statChip('攻击', weapon.attacks),
                _statChip('弹药', weapon.ammo),
                if (weapon.malfunction != '—')
                  _statChip('故障', weapon.malfunction),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Chip(
      label: Text('$label: $value', style: const TextStyle(fontSize: 12)),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _WeaponReferenceList extends StatefulWidget {
  final ScrollController scrollController;

  const _WeaponReferenceList({required this.scrollController});

  @override
  State<_WeaponReferenceList> createState() => _WeaponReferenceListState();
}

class _WeaponReferenceListState extends State<_WeaponReferenceList> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, String>> _weapons = [
    // === 近战武器 ===
    {'n': '拳头', 'sk': '格斗（斗殴）', 'dmg': '1D3', 'rng': '触碰', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '脚踢', 'sk': '格斗（斗殴）', 'dmg': '1D6', 'rng': '触碰', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '匕首', 'sk': '格斗（刃）', 'dmg': '1D4+2', 'rng': '触碰', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '短刀', 'sk': '格斗（刃）', 'dmg': '1D4+2', 'rng': '触碰', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '长剑', 'sk': '格斗（刃）', 'dmg': '1D8+2', 'rng': '触碰', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '军刀', 'sk': '格斗（刃）', 'dmg': '1D6+2', 'rng': '触碰', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '锤子', 'sk': '格斗（棍）', 'dmg': '1D6+2', 'rng': '触碰', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '警棍', 'sk': '格斗（棍）', 'dmg': '1D6+4', 'rng': '触碰', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '连枷', 'sk': '格斗（棍）', 'dmg': '1D8+2', 'rng': '触碰', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '矛', 'sk': '格斗（矛）', 'dmg': '1D6+2', 'rng': '触碰', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '斧头', 'sk': '格斗（斧）', 'dmg': '1D8+3', 'rng': '触碰', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '链枷', 'sk': '格斗（棍）', 'dmg': '2D6', 'rng': '触碰', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '弯刀', 'sk': '格斗（刃）', 'dmg': '1D6+2', 'rng': '触碰', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '鞭子', 'sk': '格斗（棍）', 'dmg': '1D3', 'rng': '5尺', 'atk': '1', 'ammo': '—', 'mal': '—'},
    // === 火器 - 手枪 ===
    {'n': '.22袖珍手枪', 'sk': '射击（火器）', 'dmg': '1D6', 'rng': '10尺', 'atk': '1', 'ammo': '7发', 'mal': '—'},
    {'n': '.25口径手枪', 'sk': '射击（火器）', 'dmg': '1D6', 'rng': '10尺', 'atk': '1', 'ammo': '7发', 'mal': '—'},
    {'n': '.32左轮', 'sk': '射击（火器）', 'dmg': '1D8', 'rng': '10尺', 'atk': '1', 'ammo': '6发', 'mal': '—'},
    {'n': '.38左轮', 'sk': '射击（火器）', 'dmg': '1D10', 'rng': '15尺', 'atk': '1', 'ammo': '6发', 'mal': '—'},
    {'n': '.38特种手枪', 'sk': '射击（火器）', 'dmg': '1D10', 'rng': '15尺', 'atk': '1', 'ammo': '6发', 'mal': '95'},
    {'n': '.45柯尔特', 'sk': '射击（火器）', 'dmg': '1D10+2', 'rng': '15尺', 'atk': '1', 'ammo': '7发', 'mal': '9'},
    {'n': '.45卫队左轮', 'sk': '射击（火器）', 'dmg': '1D10+2', 'rng': '15尺', 'atk': '1', 'ammo': '6发', 'mal': '—'},
    {'n': '9mm手枪', 'sk': '射击（火器）', 'dmg': '1D10', 'rng': '15尺', 'atk': '1', 'ammo': '8发', 'mal': '9'},
    {'n': '9mm鲁格', 'sk': '射击（火器）', 'dmg': '1D10+2', 'rng': '15尺', 'atk': '1', 'ammo': '8发', 'mal': '9'},
    {'n': '.357麦格农', 'sk': '射击（火器）', 'dmg': '2D6', 'rng': '15尺', 'atk': '1', 'ammo': '6发', 'mal': '—'},
    {'n': '.44麦格农', 'sk': '射击（火器）', 'dmg': '2D6+2', 'rng': '15尺', 'atk': '1', 'ammo': '6发', 'mal': '—'},
    {'n': '.50口径沙漠之鹰', 'sk': '射击（火器）', 'dmg': '2D10+4', 'rng': '20尺', 'atk': '1', 'ammo': '7发', 'mal': '9'},
    // === 火器 - 霰弹枪 ===
    {'n': '双管霰弹枪', 'sk': '射击（霰弹枪）', 'dmg': '2D6×2/2D6/1D6', 'rng': '10/20/50尺', 'atk': '2', 'ammo': '2发', 'mal': '9'},
    {'n': '泵动式霰弹枪', 'sk': '射击（霰弹枪）', 'dmg': '2D6/1D6/1D4', 'rng': '10/20/50尺', 'atk': '1', 'ammo': '5+1', 'mal': '9'},
    {'n': '半自动霰弹枪', 'sk': '射击（霰弹枪）', 'dmg': '2D6/1D6/1D4', 'rng': '10/20/50尺', 'atk': '1', 'ammo': '5+1', 'mal': '9'},
    // === 火器 - 步枪 ===
    {'n': '栓动步枪', 'sk': '射击（步枪）', 'dmg': '2D6+4', 'rng': '110尺', 'atk': '1', 'ammo': '5+1', 'mal': '9'},
    {'n': '半自动步枪', 'sk': '射击（步枪）', 'dmg': '2D6+4', 'rng': '110尺', 'atk': '1', 'ammo': '20发', 'mal': '9'},
    {'n': '杠杆步枪', 'sk': '射击（步枪）', 'dmg': '2D6+4', 'rng': '110尺', 'atk': '1', 'ammo': '10+1', 'mal': '9'},
    {'n': '狙击步枪', 'sk': '射击（步枪）', 'dmg': '2D6+6', 'rng': '200尺', 'atk': '1', 'ammo': '5+1', 'mal': '9'},
    // === 火器 - 冲锋枪 ===
    {'n': '冲锋枪', 'sk': '射击（冲锋枪）', 'dmg': '1D10', 'rng': '15尺', 'atk': '2/3', 'ammo': '20/30', 'mal': '9'},
    {'n': '乌兹冲锋枪', 'sk': '射击（冲锋枪）', 'dmg': '1D10', 'rng': '15尺', 'atk': '2/3', 'ammo': '32发', 'mal': '9'},
    {'n': 'MP40', 'sk': '射击（冲锋枪）', 'dmg': '1D10', 'rng': '15尺', 'atk': '2/3', 'ammo': '32发', 'mal': '9'},
    {'n': '汤普森冲锋枪', 'sk': '射击（冲锋枪）', 'dmg': '1D10+2', 'rng': '15尺', 'atk': '2/3', 'ammo': '20/30', 'mal': '9'},
    // === 火器 - 机枪 ===
    {'n': '轻机枪', 'sk': '射击（机枪）', 'dmg': '2D10+2', 'rng': '110尺', 'atk': '3', 'ammo': '100发', 'mal': '9'},
    {'n': '重机枪', 'sk': '射击（机枪）', 'dmg': '2D10+4', 'rng': '220尺', 'atk': '6', 'ammo': '250发', 'mal': '9'},
    // === 弓/弩 ===
    {'n': '短弓', 'sk': '射击（弓）', 'dmg': '1D6+2', 'rng': '30尺', 'atk': '1', 'ammo': '1箭', 'mal': '—'},
    {'n': '长弓', 'sk': '射击（弓）', 'dmg': '1D8+2', 'rng': '60尺', 'atk': '1', 'ammo': '1箭', 'mal': '—'},
    {'n': '复合弓', 'sk': '射击（弓）', 'dmg': '1D8+4', 'rng': '50尺', 'atk': '1', 'ammo': '1箭', 'mal': '—'},
    {'n': '弩', 'sk': '射击（弩）', 'dmg': '1D10', 'rng': '30尺', 'atk': '1', 'ammo': '1矢', 'mal': '—'},
    {'n': '重型弩', 'sk': '射击（弩）', 'dmg': '1D10+4', 'rng': '30尺', 'atk': '1', 'ammo': '1矢', 'mal': '—'},
    // === 投掷武器 ===
    {'n': '手里剑', 'sk': '投掷', 'dmg': '1D4', 'rng': '10尺', 'atk': '1', 'ammo': '1', 'mal': '—'},
    {'n': '飞刀', 'sk': '投掷', 'dmg': '1D4+2', 'rng': '10尺', 'atk': '1', 'ammo': '1', 'mal': '—'},
    {'n': '石块', 'sk': '投掷', 'dmg': '1D3', 'rng': '10尺', 'atk': '1', 'ammo': '1', 'mal': '—'},
    // === 其他 ===
    {'n': '火焰喷射器', 'sk': '射击（其他）', 'dmg': '2D6', 'rng': '10尺', 'atk': '1', 'ammo': '10次', 'mal': '9'},
    {'n': '电击器', 'sk': '格斗（斗殴）', 'dmg': '1D6', 'rng': '触碰', 'atk': '1', 'ammo': '—', 'mal': '—'},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredWeapons = _searchQuery.isEmpty
        ? _weapons
        : _weapons.where((w) => w['n']!.contains(_searchQuery) || w['sk']!.contains(_searchQuery)).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索武器...',
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('点击武器添加到角色', style: TextStyle(color: Colors.grey)),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: filteredWeapons.length,
            itemBuilder: (context, index) {
              final weapon = filteredWeapons[index];
              return ListTile(
                title: Text(weapon['n']!),
                subtitle: Text('技能: ${weapon['sk']} | 伤害: ${weapon['dmg']}'),
                trailing: Text('${weapon['atk']}次'),
                onTap: () {
                  final manager = Provider.of<CharacterManager>(context, listen: false);
                  manager.addWeapon(CharacterWeapon()
                    ..name = weapon['n']!
                    ..skill = _getSkillValue(weapon['sk']!)
                    ..damage = weapon['dmg']!
                    ..range = weapon['rng']!
                    ..attacks = weapon['atk']!
                    ..ammo = weapon['ammo']!
                    ..malfunction = weapon['mal']!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${weapon['n']} 已添加')),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  int _getSkillValue(String skill) {
    switch (skill) {
      case '格斗（斗殴）':
        return 25;
      case '格斗（刃）':
        return 25;
      case '格斗（棍）':
        return 25;
      case '射击（火器）':
        return 20;
      case '射击（霰弹枪）':
        return 25;
      case '射击（步枪）':
        return 25;
      case '射击（冲锋枪）':
        return 15;
      default:
        return 20;
    }
  }
}
