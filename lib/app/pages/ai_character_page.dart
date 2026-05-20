import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/character.dart';
import '../data/character_manager.dart';
import '../data/coc_data.dart';
import '../data/skill.dart';
import '../services/deepseek_service.dart';
import '../setting/app_pref.dart';

class AiCharacterPage extends StatefulWidget {
  const AiCharacterPage({super.key});

  @override
  State<AiCharacterPage> createState() => _AiCharacterPageState();
}

class _AiCharacterPageState extends State<AiCharacterPage> {
  // input
  final _descCtrl = TextEditingController();
  Occupation? _selectedOccupation;
  String? _apiKey;
  int _providerIndex = 0;

  // phase: input -> loading1 -> preview1 -> loading2 -> preview2
  String _phase = 'input';
  String _loadingText = '';
  String? _error;

  // step1 results (editable)
  Step1Result? _step1;
  final Map<String, TextEditingController> _attrCtrls = {};
  final Map<String, TextEditingController> _skillOccCtrls = {};
  final Map<String, TextEditingController> _skillIntCtrls = {};
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _residenceCtrl = TextEditingController();
  final _birthplaceCtrl = TextEditingController();

  // step2 results (editable)
  final _backstoryCtrl = TextEditingController();
  final _appearanceCtrl = TextEditingController();
  List<_EditableItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final appPref = AppPreferences(prefs);
    setState(() {
      _providerIndex = appPref.aiProviderIndex;
      _apiKey = _providerIndex == 0 ? appPref.getDeepseekApiKey() : appPref.getMimoApiKey();
    });
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _genderCtrl.dispose();
    _residenceCtrl.dispose();
    _birthplaceCtrl.dispose();
    _backstoryCtrl.dispose();
    _appearanceCtrl.dispose();
    for (final c in _attrCtrls.values) c.dispose();
    for (final c in _skillOccCtrls.values) c.dispose();
    for (final c in _skillIntCtrls.values) c.dispose();
    super.dispose();
  }

  AiService? _getService() {
    if (_apiKey == null || _apiKey!.isEmpty) return null;
    return AiService(apiKey: _apiKey!, provider: AiProvider.values[_providerIndex]);
  }

  Future<void> _generateStep1() async {
    // 重新加载 API Key（从设置页返回后可能已更新）
    await _loadApiKey();
    if (!mounted) return;
    final service = _getService();
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请先在设置页配置 ${AiProvider.values[_providerIndex].label} API Key'),
          action: SnackBarAction(label: '去设置', onPressed: () => Navigator.pushNamed(context, '/settings')),
        ),
      );
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入角色描述')),
      );
      return;
    }

    setState(() {
      _phase = 'loading1';
      _loadingText = 'AI 正在生成属性与技能...';
      _error = null;
    });

    try {
      final result = await service.generateStep1(
        _descCtrl.text.trim(),
        _selectedOccupation?.n,
      );
      if (!mounted) return;
      _initStep1Editors(result);
      setState(() => _phase = 'preview1');
    } catch (e) {
      setState(() {
        _phase = 'input';
        _error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    }
  }

  void _initStep1Editors(Step1Result result) {
    _step1 = result;
    _nameCtrl.text = result.name;
    _ageCtrl.text = result.age;
    _genderCtrl.text = result.gender;
    _residenceCtrl.text = result.residence;
    _birthplaceCtrl.text = result.birthplace;

    _attrCtrls.clear();
    for (final entry in result.attributes.entries) {
      _attrCtrls[entry.key] = TextEditingController(text: entry.value.toString());
    }

    _skillOccCtrls.clear();
    _skillIntCtrls.clear();
    for (final entry in result.skills.entries) {
      _skillOccCtrls[entry.key] = TextEditingController(text: entry.value.occ.toString());
      _skillIntCtrls[entry.key] = TextEditingController(text: entry.value.interest.toString());
    }
  }

  int _getAttr(String key) => int.tryParse(_attrCtrls[key]?.text ?? '') ?? 0;

  int _getOccPointTotal() {
    final occ = _step1?.occId != null
        ? OCCUPATIONS.where((o) => o.id == _step1!.occId).firstOrNull
        : null;
    if (occ == null) return 0;
    return calcOccupationPoints(occ.attr, {
      '力量': _getAttr('str'), '体质': _getAttr('con'), '体型': _getAttr('siz'),
      '敏捷': _getAttr('dex'), '外貌': _getAttr('app'), '智力': _getAttr('int'),
      '意志': _getAttr('pow'), '教育': _getAttr('edu'),
    });
  }

  int _getIntPointTotal() => _getAttr('int') * 2;

  int _getOccPointSpent() {
    int total = 0;
    for (final c in _skillOccCtrls.values) {
      total += int.tryParse(c.text) ?? 0;
    }
    return total;
  }

  int _getIntPointSpent() {
    int total = 0;
    for (final c in _skillIntCtrls.values) {
      total += int.tryParse(c.text) ?? 0;
    }
    return total;
  }

  Future<void> _generateStep2() async {
    await _loadApiKey();
    if (!mounted) return;
    final service = _getService();
    if (service == null) return;

    // 更新 step1 数据
    _step1!.name = _nameCtrl.text;
    _step1!.age = _ageCtrl.text;
    _step1!.gender = _genderCtrl.text;
    _step1!.residence = _residenceCtrl.text;
    _step1!.birthplace = _birthplaceCtrl.text;
    for (final entry in _attrCtrls.entries) {
      _step1!.attributes[entry.key] = int.tryParse(entry.value.text) ?? 50;
    }

    setState(() {
      _phase = 'loading2';
      _loadingText = 'AI 正在生成背景与物品...';
      _error = null;
    });

    try {
      final result = await service.generateStep2(_descCtrl.text.trim(), _step1!);
      if (!mounted) return;
      _backstoryCtrl.text = result.backstory;
      _appearanceCtrl.text = result.appearance;
      _items = result.items.map((i) => _EditableItem(
        nameCtrl: TextEditingController(text: i.name),
        countCtrl: TextEditingController(text: i.count.toString()),
      )).toList();
      setState(() => _phase = 'preview2');
    } catch (e) {
      setState(() => _phase = 'preview1');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    }
  }

  Future<void> _applyCharacter() async {
    final manager = context.read<CharacterManager>();

    await manager.createNewCharacter();
    final c = manager.character;

    // 基本信息
    c.name = _nameCtrl.text.isEmpty ? '新角色' : _nameCtrl.text;
    c.age = _ageCtrl.text;
    c.gender = _genderCtrl.text;
    c.residence = _residenceCtrl.text;
    c.birthplace = _birthplaceCtrl.text;

    // 属性
    manager.setAttributes(
      str: _getAttr('str'), con: _getAttr('con'), siz: _getAttr('siz'),
      dex: _getAttr('dex'), app: _getAttr('app'), int_: _getAttr('int'),
      pow: _getAttr('pow'), edu: _getAttr('edu'),
    );

    // 职业
    if (_step1?.occId != null) {
      final occ = OCCUPATIONS.where((o) => o.id == _step1!.occId).firstOrNull;
      if (occ != null) manager.applyOccupation(occ);
    }

    // 技能
    for (final entry in _skillOccCtrls.entries) {
      final occVal = int.tryParse(entry.value.text) ?? 0;
      final intVal = int.tryParse(_skillIntCtrls[entry.key]?.text ?? '') ?? 0;
      final skillDef = SKILL_DEFS.where((s) => s.key == entry.key).firstOrNull;
      final baseVal = skillDef?.baseHalf ?? 0;
      c.skills[entry.key] = baseVal + occVal + intVal;
    }
    // 也写入仅有兴趣点的技能
    for (final entry in _skillIntCtrls.entries) {
      if (!_skillOccCtrls.containsKey(entry.key)) {
        final intVal = int.tryParse(entry.value.text) ?? 0;
        final skillDef = SKILL_DEFS.where((s) => s.key == entry.key).firstOrNull;
        final baseVal = skillDef?.baseHalf ?? 0;
        c.skills[entry.key] = baseVal + intVal;
      }
    }
    c.occupationPointSpent = _getOccPointSpent();
    c.interestPointSpent = _getIntPointSpent();

    // 背景和外貌
    manager.updateBackstory(_backstoryCtrl.text);
    manager.updateAppearance(_appearanceCtrl.text);

    // 物品
    final items = _items.map((i) => CharacterItem(
      name: i.nameCtrl.text,
      count: int.tryParse(i.countCtrl.text) ?? 1,
    )).toList();
    manager.updateItems(items);

    manager.selectCharacter(c.id);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 辅助建卡')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case 'loading1':
      case 'loading2':
        return _buildLoading();
      case 'preview1':
        return _buildPreview1();
      case 'preview2':
        return _buildPreview2();
      default:
        return _buildInput();
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(_loadingText, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('请稍候，AI 思考中...', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('描述你的角色', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '提供角色的大体描述，AI 会根据描述生成属性、技能、背景等',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: '例如：一个来自阿卡姆的大学教授，研究古代神话，性格内向但学识渊博，曾多次参与考古探险...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text('选择职业（可选）', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_selectedOccupation != null)
            Card(
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                title: Text(_selectedOccupation!.n),
                subtitle: Text('信用: ${_selectedOccupation!.min}-${_selectedOccupation!.max}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedOccupation = null),
                ),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: _showOccupationPicker,
              icon: const Icon(Icons.work_outline),
              label: const Text('选择职业（留空则由 AI 推荐）'),
            ),
          const SizedBox(height: 32),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _generateStep1,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('生成属性与技能', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview1() {
    final occSpent = _getOccPointSpent();
    final intSpent = _getIntPointSpent();
    final occTotal = _getOccPointTotal();
    intTotal = _getIntPointTotal();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('基本信息'),
                _editableRow('角色名', _nameCtrl),
                _editableRow('年龄', _ageCtrl),
                _editableRow('性别', _genderCtrl),
                _editableRow('居住地', _residenceCtrl),
                _editableRow('出生地', _birthplaceCtrl),
                const SizedBox(height: 16),
                _buildSectionTitle('属性'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _attrCtrls.entries.map((e) => _attrEditBox(e.key, e.value)).toList(),
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('技能分配'),
                _buildPointSummary(occSpent, occTotal, intSpent, intTotal),
                const SizedBox(height: 8),
                ..._skillOccCtrls.keys.map((name) => _skillEditRow(name)),
                // 仅有兴趣点的技能
                ..._skillIntCtrls.keys
                    .where((k) => !_skillOccCtrls.containsKey(k))
                    .map((name) => _skillEditRow(name)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _generateStep2,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('下一步：生成背景与物品'),
            ),
          ),
        ),
      ],
    );
  }

  int intTotal = 0;

  Widget _buildPointSummary(int occSpent, int occTotal, int intSpent, int intTotal) {
    final occOk = occSpent <= occTotal;
    final intOk = intSpent <= intTotal;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('职业点数', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                Text(
                  '$occSpent / $occTotal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: occOk ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text('兴趣点数', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.tertiary)),
                Text(
                  '$intSpent / $intTotal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: intOk ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview2() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('背景故事'),
                TextField(
                  controller: _backstoryCtrl,
                  maxLines: 8,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('外貌描述'),
                TextField(
                  controller: _appearanceCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('背包物品'),
                ..._items.asMap().entries.map((e) => _itemEditRow(e.key, e.value)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _items.add(_EditableItem())),
                  icon: const Icon(Icons.add),
                  label: const Text('添加物品'),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _applyCharacter,
              icon: const Icon(Icons.check),
              label: const Text('完成创建', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }

  Widget _editableRow(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(
            child: TextField(controller: ctrl, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder())),
          ),
        ],
      ),
    );
  }

  Widget _attrEditBox(String key, TextEditingController ctrl) {
    final labels = {'str': '力量', 'con': '体质', 'siz': '体型', 'dex': '敏捷', 'app': '外貌', 'int': '智力', 'pow': '意志', 'edu': '教育'};
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Text(labels[key] ?? key, style: const TextStyle(fontSize: 12)),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _skillEditRow(String name) {
    final occCtrl = _skillOccCtrls[name];
    final intCtrl = _skillIntCtrls[name];
    final skillDef = SKILL_DEFS.where((s) => s.key == name).firstOrNull;
    final baseVal = skillDef?.baseHalf ?? 0;
    final occVal = int.tryParse(occCtrl?.text ?? '') ?? 0;
    final intVal = int.tryParse(intCtrl?.text ?? '') ?? 0;
    final total = baseVal + occVal + intVal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name, style: const TextStyle(fontSize: 13))),
          if (occCtrl != null) ...[
            SizedBox(
              width: 55,
              child: TextField(
                controller: occCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(isDense: true, prefixText: '职', prefixStyle: TextStyle(fontSize: 10)),
                style: const TextStyle(fontSize: 13),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
          if (intCtrl != null) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 55,
              child: TextField(
                controller: intCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(isDense: true, prefixText: '兴', prefixStyle: TextStyle(fontSize: 10)),
                style: const TextStyle(fontSize: 13),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
          const SizedBox(width: 4),
          SizedBox(width: 50, child: Text('= $total%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _itemEditRow(int index, _EditableItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: item.nameCtrl,
              decoration: const InputDecoration(isDense: true, hintText: '物品名称'),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: TextField(
              controller: item.countCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(isDense: true, prefixText: '×'),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _items.removeAt(index)),
          ),
        ],
      ),
    );
  }

  void _showOccupationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('选择职业', style: Theme.of(ctx).textTheme.titleLarge),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: OCCUPATIONS.length,
                itemBuilder: (ctx, index) {
                  final occ = OCCUPATIONS[index];
                  return ListTile(
                    title: Text(occ.n),
                    subtitle: Text('${occ.attr} | 信用 ${occ.min}-${occ.max}'),
                    onTap: () {
                      setState(() => _selectedOccupation = occ);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableItem {
  final TextEditingController nameCtrl;
  final TextEditingController countCtrl;
  _EditableItem({TextEditingController? nameCtrl, TextEditingController? countCtrl})
      : nameCtrl = nameCtrl ?? TextEditingController(),
        countCtrl = countCtrl ?? TextEditingController(text: '1');
}
