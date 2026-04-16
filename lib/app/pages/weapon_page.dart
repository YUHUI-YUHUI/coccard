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
    {'n': '弓箭', 'sk': '弓', 'dmg': '1D6+半DB', 'rng': '30码', 'atk': '1', 'ammo': '1', 'mal': '97'},
    {'n': '弓(弓道用)', 'sk': '弓', 'dmg': '1D6+1', 'rng': '90码', 'atk': '1', 'ammo': '1', 'mal': '—'},
    {'n': '丛林狩猎弓', 'sk': '弓', 'dmg': '1D6+DB', 'rng': '30码', 'atk': '1', 'ammo': '1', 'mal': '90'},
    {'n': '弩', 'sk': '弓', 'dmg': '1D8+2', 'rng': '50码', 'atk': '1/2', 'ammo': '1', 'mal': '96'},
    {'n': '黄铜指虎', 'sk': '斗殴', 'dmg': '1D3+1+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '小型棍状物(警棍等)', 'sk': '斗殴', 'dmg': '1D6+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '燃烧的火把', 'sk': '斗殴', 'dmg': '1D6+燃烧', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '包皮铁棍(甩棍、大头棍、护身棒)', 'sk': '斗殴', 'dmg': '1D8+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '大型棍状物(棒球棍、板球棒、拨火棍等)', 'sk': '斗殴', 'dmg': '1D8+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '小型刀具(弹簧折叠刀等)', 'sk': '斗殴', 'dmg': '1D4+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '中型刀具(切肉菜刀等)', 'sk': '斗殴', 'dmg': '1D4+2+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '大型刀具(甘蔗刀等)', 'sk': '斗殴', 'dmg': '1D8+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '轻型剑（花剑、剑杖）', 'sk': '剑', 'dmg': '1D6+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '中型剑（佩剑、重剑）', 'sk': '剑', 'dmg': '1D6+1+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '大型剑（马刀）', 'sk': '剑', 'dmg': '1D8+1+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '日本刀', 'sk': '剑', 'dmg': '1D10+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '大刀(中式大刀等)', 'sk': '剑', 'dmg': '2D6+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '太刀', 'sk': '剑', 'dmg': '2D8+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '手斧/镰刀', 'sk': '斧', 'dmg': '1D6+1+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '伐木斧', 'sk': '斧', 'dmg': '1D8+2+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '双节棍', 'sk': '链枷', 'dmg': '1D8+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '三节棍', 'sk': '链枷', 'dmg': '1D10+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '锁镰', 'sk': '链枷', 'dmg': '1D6或缠卷', 'rng': '3码', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '矛、骑士长枪', 'sk': '矛', 'dmg': '1D8+1', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '长矛', 'sk': '矛', 'dmg': '1D10+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '投石', 'sk': '投掷', 'dmg': '1D4+半DB', 'rng': 'STR英尺', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '手里剑', 'sk': '投掷', 'dmg': '1D3+半DB', 'rng': '20码', 'atk': '2', 'ammo': '一次性', 'mal': '100'},
    {'n': '掷矛', 'sk': '投掷', 'dmg': '1D8+半DB', 'rng': 'STR码', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '战斗回力镖', 'sk': '投掷', 'dmg': '1D8+半DB', 'rng': '20码', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '长鞭', 'sk': '鞭子', 'dmg': '1D3+半DB', 'rng': '10英尺', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '电锯', 'sk': '电锯', 'dmg': '2D8', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '95'},
    {'n': '绞具', 'sk': '绞具', 'dmg': '1D6+DB', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '—'},
    {'n': '220v通电导线', 'sk': '斗殴', 'dmg': '2D8+眩晕', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '95'},
    {'n': '电棍、电击枪(接触)', 'sk': '斗殴', 'dmg': '1D3+眩晕', 'rng': '接触', 'atk': '1', 'ammo': '—', 'mal': '97'},
    {'n': '电击枪(远程)', 'sk': '手枪', 'dmg': '1D3+眩晕', 'rng': '15英尺', 'atk': '1', 'ammo': '3', 'mal': '95'},
    {'n': '遂发枪', 'sk': '手枪', 'dmg': '1D6+1', 'rng': '10', 'atk': '1/4', 'ammo': '1', 'mal': '95'},
    {'n': '.22(5.6mm)小型自动手枪', 'sk': '手枪', 'dmg': '1D6', 'rng': '10', 'atk': '1(3)', 'ammo': '6', 'mal': '100'},
    {'n': '.25(6.35mm)短口手枪(单管)', 'sk': '手枪', 'dmg': '1D6', 'rng': '3', 'atk': '1', 'ammo': '1', 'mal': '100'},
    {'n': '7.62mm托卡列夫 (54式)', 'sk': '手枪', 'dmg': '1D6+2', 'rng': '15', 'atk': '1(3)', 'ammo': '8', 'mal': '95'},
    {'n': '.32(7.65mm)左轮手枪', 'sk': '手枪', 'dmg': '1D8', 'rng': '15', 'atk': '1(3)', 'ammo': '6', 'mal': '100'},
    {'n': '.32(7.65mm)自动手枪', 'sk': '手枪', 'dmg': '1D8', 'rng': '15', 'atk': '1(3)', 'ammo': '8', 'mal': '99'},
    {'n': '7.63mm毛瑟C96 (盒子炮)', 'sk': '手枪', 'dmg': '1D8+2', 'rng': '30', 'atk': '1(3)', 'ammo': '10', 'mal': '99'},
    {'n': '.38(9mm)左轮手枪', 'sk': '手枪', 'dmg': '1D10', 'rng': '15', 'atk': '1(3)', 'ammo': '6', 'mal': '100'},
    {'n': '.38(9mm)自动手枪', 'sk': '手枪', 'dmg': '1D10', 'rng': '15', 'atk': '1(3)', 'ammo': '8', 'mal': '99'},
    {'n': '贝瑞塔 M9', 'sk': '手枪', 'dmg': '1D10', 'rng': '15', 'atk': '1(3)', 'ammo': '15', 'mal': '98'},
    {'n': '9mm 格洛克 17', 'sk': '手枪', 'dmg': '1D10', 'rng': '15', 'atk': '1(3)', 'ammo': '17', 'mal': '98'},
    {'n': '9mm 鲁格 P08', 'sk': '手枪', 'dmg': '1D10', 'rng': '15', 'atk': '1(3)', 'ammo': '8', 'mal': '99'},
    {'n': '.41(10.4mm) 左轮手枪', 'sk': '手枪', 'dmg': '1D10', 'rng': '15', 'atk': '1(3)', 'ammo': '6', 'mal': '100'},
    {'n': '勃朗宁High-Power自动手枪', 'sk': '手枪', 'dmg': '1D10', 'rng': '15', 'atk': '1(3)', 'ammo': '13', 'mal': '98'},
    {'n': 'FN57式自动手枪', 'sk': '手枪', 'dmg': '1D10+1', 'rng': '15', 'atk': '1(3)', 'ammo': '20', 'mal': '98'},
    {'n': '.357 马格南左轮手枪', 'sk': '手枪', 'dmg': '1D8+1D4', 'rng': '15', 'atk': '1(3)', 'ammo': '6', 'mal': '100'},
    {'n': '.44-40温彻斯特弹左轮手枪', 'sk': '手枪', 'dmg': '1D8+1D6', 'rng': '15', 'atk': '1(3)', 'ammo': '6', 'mal': '100'},
    {'n': '.44(11.2mm) 马格南左轮手枪', 'sk': '手枪', 'dmg': '1D10+1D4+2', 'rng': '15', 'atk': '1(3)', 'ammo': '6', 'mal': '100'},
    {'n': '.45(11.43mm) 左轮手枪', 'sk': '手枪', 'dmg': '1D10+2', 'rng': '15', 'atk': '1(3)', 'ammo': '6', 'mal': '100'},
    {'n': '.45(11.43mm) 自动手枪', 'sk': '手枪', 'dmg': '1D10+2', 'rng': '15', 'atk': '1(3)', 'ammo': '7', 'mal': '100'},
    {'n': 'IMI 沙漠之鹰', 'sk': '手枪', 'dmg': '1D10+1D6+3', 'rng': '15', 'atk': '1(3)', 'ammo': '7', 'mal': '94'},
    {'n': '.58 (14.7mm)1855 年式春田步枪', 'sk': '步枪/霰弹枪', 'dmg': '1D10+4', 'rng': '60', 'atk': '1/4', 'ammo': '1', 'mal': '95'},
    {'n': '.45 马提尼·亨利步枪', 'sk': '步枪/霰弹枪', 'dmg': '1D8+1D6+3', 'rng': '80', 'atk': '1/3', 'ammo': '1', 'mal': '100'},
    {'n': '莫兰上校的气动步枪', 'sk': '步枪/霰弹枪', 'dmg': '2D6+1', 'rng': '20', 'atk': '1/3', 'ammo': '1', 'mal': '88'},
    {'n': '.22 (5.6mm)栓式枪机步枪', 'sk': '步枪/霰弹枪', 'dmg': '1D6+1', 'rng': '30', 'atk': '1', 'ammo': '6', 'mal': '99'},
    {'n': '.22 (5.6mm) 马林1891/M39步枪', 'sk': '步枪/霰弹枪', 'dmg': '1D6+2', 'rng': '30', 'atk': '1(3)', 'ammo': '19', 'mal': '99'},
    {'n': '.44-40 温彻斯特M1892杠杆式步枪', 'sk': '步枪/霰弹枪', 'dmg': '1D10+2', 'rng': '50', 'atk': '1', 'ammo': '11', 'mal': '98'},
    {'n': '.30 (7.62mm)杠杆式枪机步枪', 'sk': '步枪/霰弹枪', 'dmg': '2D6', 'rng': '50', 'atk': '1', 'ammo': '6', 'mal': '98'},
    {'n': 'SKS 半自动步枪(56 半)', 'sk': '步枪/霰弹枪', 'dmg': '2D6+1', 'rng': '90', 'atk': '1(2)', 'ammo': '10', 'mal': '97'},
    {'n': '加兰德M1、M2步枪', 'sk': '步枪/霰弹枪', 'dmg': '2D6+4', 'rng': '110', 'atk': '1', 'ammo': '8', 'mal': '100'},
    {'n': '.303 (7.7mm) 李·恩菲尔德', 'sk': '步枪/霰弹枪', 'dmg': '2D6+4', 'rng': '110', 'atk': '1', 'ammo': '5', 'mal': '100'},
    {'n': '.30——06 (7.62mm) 栓式枪机步枪', 'sk': '步枪/霰弹枪', 'dmg': '2D6+4', 'rng': '110', 'atk': '1', 'ammo': '5', 'mal': '100'},
    {'n': '.30——06 (7.62mm) 半自动步枪', 'sk': '步枪/霰弹枪', 'dmg': '2D6+4', 'rng': '110', 'atk': '1', 'ammo': '5', 'mal': '100'},
    {'n': '柯尔特M1918 BAR', 'sk': '步枪/霰弹枪', 'dmg': '2D6+4', 'rng': '110', 'atk': '1(2)or全自动', 'ammo': '20', 'mal': '98'},
    {'n': '.405 温彻斯特M1895步枪', 'sk': '步枪/霰弹枪', 'dmg': '2d6+1d4+2', 'rng': '75', 'atk': '1', 'ammo': '4', 'mal': '99'},
    {'n': '.444 (11.28mm) 马林步枪', 'sk': '步枪/霰弹枪', 'dmg': '2D8+4', 'rng': '110', 'atk': '1', 'ammo': '5', 'mal': '98'},
    {'n': '.577 Nitro Express弹双管步枪', 'sk': '步枪/霰弹枪', 'dmg': '2d6+1d4+3', 'rng': '50', 'atk': '1 or 2', 'ammo': '2', 'mal': '96'},
    {'n': '猎象枪(双管)', 'sk': '步枪/霰弹枪', 'dmg': '3D6+4', 'rng': '100', 'atk': '1 or 2', 'ammo': '2', 'mal': '100'},
    {'n': '巴雷特M82', 'sk': '步枪/霰弹枪', 'dmg': '2D10+1D8+6', 'rng': '250', 'atk': '1', 'ammo': '11', 'mal': '96'},
    {'n': '20 号霰弹枪(双管)', 'sk': '步枪/霰弹枪', 'dmg': '2D6/1D6/1D3', 'rng': '10/20/50', 'atk': '1 or 2', 'ammo': '2', 'mal': '100'},
    {'n': '16 号霰弹枪(双管)', 'sk': '步枪/霰弹枪', 'dmg': '2D6+2/1D6+1/1D4', 'rng': '10/20/50', 'atk': '1 or 2', 'ammo': '2', 'mal': '100'},
    {'n': '12 号霰弹枪(双管)', 'sk': '步枪/霰弹枪', 'dmg': '4D6/2D6/1D6', 'rng': '10/20/50', 'atk': '1 or 2', 'ammo': '2', 'mal': '100'},
    {'n': '12 号霰弹枪(泵动)', 'sk': '步枪/霰弹枪', 'dmg': '4D6/2D6/1D6', 'rng': '10/20/50', 'atk': '1', 'ammo': '5', 'mal': '100'},
    {'n': '12 号霰弹枪(半自动)', 'sk': '步枪/霰弹枪', 'dmg': '4D6/2D6/1D6', 'rng': '10/20/50', 'atk': '1(2)', 'ammo': '5', 'mal': '100'},
    {'n': '12 号霰弹枪(双管,锯短)', 'sk': '步枪/霰弹枪', 'dmg': '4D6/1D6', 'rng': '5/10', 'atk': '1 or 2', 'ammo': '2', 'mal': '100'},
    {'n': '10 号霰弹枪(双管)', 'sk': '步枪/霰弹枪', 'dmg': '4D6+2/2D6+1/1D4', 'rng': '10/20/50', 'atk': '1 or 2', 'ammo': '2', 'mal': '100'},
    {'n': '勃朗宁Auto-5 12号霰弹枪', 'sk': '步枪/霰弹枪', 'dmg': '4D6/2D6/1D6', 'rng': '10/20/50', 'atk': '1(2)', 'ammo': '3/5', 'mal': '100'},
    {'n': '12 号贝里尼 M3(折叠式枪托)', 'sk': '步枪/霰弹枪', 'dmg': '4D6/2D6/1D6', 'rng': '10/20/50', 'atk': '1(2)', 'ammo': '7', 'mal': '100'},
    {'n': '12 号 SPAS (折叠式枪托)', 'sk': '步枪/霰弹枪', 'dmg': '4D6/2D6/1D6', 'rng': '10/20/50', 'atk': '1', 'ammo': '8', 'mal': '98'},
    {'n': '"一字马"Saiga-12半自动霰弹枪', 'sk': '步枪/霰弹枪', 'dmg': '4D6/2D6/1D6', 'rng': '10/20/50', 'atk': '1(2)', 'ammo': '5/8', 'mal': '98'},
    {'n': 'AK-47 或 AKM', 'sk': '步枪/霰弹枪', 'dmg': '2D6+1', 'rng': '100', 'atk': '1(2)or全自动', 'ammo': '30', 'mal': '100'},
    {'n': 'AK-74', 'sk': '步枪/霰弹枪', 'dmg': '2D6+1', 'rng': '110', 'atk': '1(2)or全自动', 'ammo': '30', 'mal': '97'},
    {'n': 'FN FAL', 'sk': '步枪/霰弹枪', 'dmg': '2D6+4', 'rng': '110', 'atk': '1(2)or3连射', 'ammo': '20', 'mal': '97'},
    {'n': '加利尔突击步枪', 'sk': '步枪/霰弹枪', 'dmg': '2D6', 'rng': '110', 'atk': '1(2)or连射', 'ammo': '20', 'mal': '98'},
    {'n': 'M16A2', 'sk': '步枪/霰弹枪', 'dmg': '2D6', 'rng': '110', 'atk': '1(2)or3连射', 'ammo': '30', 'mal': '97'},
    {'n': 'M4', 'sk': '步枪/霰弹枪', 'dmg': '2D6', 'rng': '90', 'atk': '1or3连射', 'ammo': '30', 'mal': '97'},
    {'n': '斯泰尔 AUG', 'sk': '步枪/霰弹枪', 'dmg': '2D6', 'rng': '110', 'atk': '1(2)or全自动', 'ammo': '30', 'mal': '99'},
    {'n': '贝雷塔 M70/90', 'sk': '步枪/霰弹枪', 'dmg': '2D6', 'rng': '110', 'atk': '1or全自动', 'ammo': '30', 'mal': '99'},
    {'n': 'MP18I/MP28II', 'sk': '冲锋枪', 'dmg': '1D10', 'rng': '20', 'atk': '1(2)or全自动', 'ammo': '20/30/32', 'mal': '96'},
    {'n': 'MP5', 'sk': '冲锋枪', 'dmg': '1D10', 'rng': '20', 'atk': '1(2)or全自动', 'ammo': '15/30', 'mal': '97'},
    {'n': 'MAC-11', 'sk': '冲锋枪', 'dmg': '1D10', 'rng': '15', 'atk': '1(3)or全自动', 'ammo': '32', 'mal': '96'},
    {'n': '蝎式冲锋枪', 'sk': '冲锋枪', 'dmg': '1D8', 'rng': '15', 'atk': '1(3)or全自动', 'ammo': '20', 'mal': '96'},
    {'n': 'FN P90', 'sk': '冲锋枪', 'dmg': '1D10+1', 'rng': '30', 'atk': '1(3)or全自动', 'ammo': '10/30/50', 'mal': '98'},
    {'n': '汤普森冲锋枪', 'sk': '冲锋枪', 'dmg': '1D10+2', 'rng': '20', 'atk': '1or全自动', 'ammo': '20/30/50', 'mal': '96'},
    {'n': '乌兹微型冲锋枪', 'sk': '冲锋枪', 'dmg': '1D10', 'rng': '20', 'atk': '1(2)or全自动', 'ammo': '32', 'mal': '98'},
    {'n': '1882 年式加特林', 'sk': '机枪', 'dmg': '2D6+4', 'rng': '100', 'atk': '全自动', 'ammo': '200', 'mal': '96'},
    {'n': 'M1918 式勃朗宁自动步枪', 'sk': '机枪', 'dmg': '2D6+4', 'rng': '90', 'atk': '1(2)or全自动', 'ammo': '20', 'mal': '100'},
    {'n': '勃朗宁 M1917A1(7.62mm)', 'sk': '机枪', 'dmg': '2D6+4', 'rng': '150', 'atk': '全自动', 'ammo': '250', 'mal': '96'},
    {'n': '布伦轻机枪', 'sk': '机枪', 'dmg': '2D6+4', 'rng': '110', 'atk': '1or全自动', 'ammo': '30/100', 'mal': '96'},
    {'n': '路易斯Ⅰ型机枪', 'sk': '机枪', 'dmg': '2D6+4', 'rng': '110', 'atk': '全自动', 'ammo': '27/97', 'mal': '96'},
    {'n': 'GE M134 式 7.62mm 速射机枪', 'sk': '机枪', 'dmg': '2D6+4', 'rng': '200', 'atk': '全自动', 'ammo': '4000', 'mal': '98'},
    {'n': 'FN 米尼米(5.56mm)，弹夹/弹带', 'sk': '机枪', 'dmg': '2D6', 'rng': '110', 'atk': '全自动', 'ammo': '30/200', 'mal': '99'},
    {'n': '维克斯.303 机枪', 'sk': '机枪', 'dmg': '2D6+4', 'rng': '110', 'atk': '全自动', 'ammo': '250', 'mal': '99'},
    {'n': '莫洛托夫燃烧瓶', 'sk': '投掷', 'dmg': '2D6+燃烧', 'rng': 'STR码', 'atk': '1/2', 'ammo': '一次性', 'mal': '95'},
    {'n': '信号枪(信号弹枪)', 'sk': '手枪', 'dmg': '1D10+1D3+燃烧', 'rng': '10', 'atk': '1/2', 'ammo': '1', 'mal': '100'},
    {'n': 'M79 40mm 榴弹发射器', 'sk': '重武器', 'dmg': '3D10/2码', 'rng': '20', 'atk': '1/3', 'ammo': '1', 'mal': '99'},
    {'n': '雷管', 'sk': '电气维修', 'dmg': '2D10/1码', 'rng': 'N/A', 'atk': 'N/A', 'ammo': '一次性', 'mal': '100'},
    {'n': '爆破筒', 'sk': '爆破', 'dmg': '1D10/3码', 'rng': '就地', 'atk': '一次使用', 'ammo': '一次性', 'mal': '95'},
    {'n': '塑胶炸弹(C4) 100克', 'sk': '爆破', 'dmg': '6D10/3码', 'rng': '就地', 'atk': '一次使用', 'ammo': '一次性', 'mal': '99'},
    {'n': '炸药棒', 'sk': '投掷', 'dmg': '4D10/3码', 'rng': 'STR英尺', 'atk': '1/2', 'ammo': '一次性', 'mal': '99'},
    {'n': '手榴弹', 'sk': '投掷', 'dmg': '4D10/3码', 'rng': 'STR英尺', 'atk': '1/2', 'ammo': '一次性', 'mal': '99'},
    {'n': '81mm迫击炮', 'sk': '炮术', 'dmg': '6D10/6码', 'rng': '500码', 'atk': '2', 'ammo': '独立装弹', 'mal': '100'},
    {'n': '75mm野战火炮', 'sk': '炮术', 'dmg': '10D10/2码', 'rng': '500码', 'atk': '1/4', 'ammo': '独立装弹', 'mal': '99'},
    {'n': '120mm坦克炮(稳定)', 'sk': '炮术', 'dmg': '10D10/2码', 'rng': '2000码', 'atk': '1', 'ammo': '独立装弹', 'mal': '100'},
    {'n': '5英寸舰载炮(稳定)', 'sk': '炮术', 'dmg': '15D10/4码', 'rng': '3000码', 'atk': '1', 'ammo': '自动上弹', 'mal': '98'},
    {'n': '反步兵地雷', 'sk': '爆破', 'dmg': '4D10/5码', 'rng': '就地', 'atk': '布置', 'ammo': '一次性', 'mal': '99'},
    {'n': '阔剑地雷', 'sk': '爆破', 'dmg': '6D6/20码', 'rng': '就地', 'atk': '布置', 'ammo': '一次性', 'mal': '99'},
    {'n': '火焰喷射器', 'sk': '喷射器', 'dmg': '2D6+燃烧', 'rng': '25码', 'atk': '1', 'ammo': '至少10', 'mal': '93'},
    {'n': 'M72 式单发轻型反坦克炮', 'sk': '重武器', 'dmg': '8d10/1码', 'rng': '150码', 'atk': '1', 'ammo': '1', 'mal': '98'},
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
