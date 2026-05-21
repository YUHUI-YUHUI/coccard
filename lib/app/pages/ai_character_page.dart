import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/character.dart';
import '../data/character_manager.dart';
import '../data/coc_data.dart';
import '../data/skill.dart';
import '../data/allocation_rule.dart';
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

  // phase: input -> destinySelect (天命模式) -> loading1 -> preview1 -> loading2 -> preview2
  String _phase = 'input';
  String _loadingText = '';
  String? _error;

  // 属性分配规则
  AllocationRule _allocRule = AllocationRule.defaultRule;
  final TextEditingController _destinyGroupsCtrl = TextEditingController(text: '3');
  final TextEditingController _pointBuyTotalCtrl = TextEditingController(text: '480');
  // 天命候选与选择
  List<Map<String, int>> _destinyCandidates = [];
  int _destinyPicked = -1;
  // 单独投出的运气（不含运模式）
  int _separateLuck = 0;

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
      _apiKey = appPref.getDeepseekApiKey();
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
    _destinyGroupsCtrl.dispose();
    _pointBuyTotalCtrl.dispose();
    super.dispose();
  }

  AiService? _getService() {
    if (_apiKey == null || _apiKey!.isEmpty) return null;
    return AiService(apiKey: _apiKey!);
  }

  Future<void> _onGeneratePressed() async {
    await _loadApiKey();
    if (!mounted) return;
    final service = _getService();
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请先在设置页配置 DeepSeek API Key'),
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
    // 解析描述中的规则；未匹配则使用当前 _allocRule（默认 480 购点不含运）
    final parsed = AllocationRule.parseFromDescription(_descCtrl.text);
    if (parsed != null) {
      setState(() {
        _allocRule = parsed;
        _destinyGroupsCtrl.text = parsed.destinyGroups.toString();
        _pointBuyTotalCtrl.text = parsed.pointBuyTotal.toString();
      });
    }

    // 始终先本地骰一次运气作为默认（destiny+含运 时会被选中的组覆盖）
    _separateLuck = CocDice.rollLuck(Random());

    if (_allocRule.method == AllocationMethod.destiny) {
      // 天命：本地骰 N 组，进入选择阶段
      final r = Random();
      setState(() {
        _destinyCandidates = List.generate(
          _allocRule.destinyGroups,
          (_) => CocDice.rollAttributeSet(r, includeLuck: _allocRule.includeLuck),
        );
        _destinyPicked = -1;
        _phase = 'destinySelect';
        _error = null;
      });
    } else {
      // 购点：直接交给 AI 生成
      await _runStep1Generation(fixedAttrs: null);
    }
  }

  Future<void> _confirmDestinyAndGenerate() async {
    if (_destinyPicked < 0) return;
    final chosen = _destinyCandidates[_destinyPicked];
    if (chosen.containsKey('luck')) {
      _separateLuck = chosen['luck']!;
    }
    // 把 9 元转 8 元供 AI 用（不传 luck）
    final fixedAttrs = <String, int>{
      'str': chosen['str']!, 'con': chosen['con']!, 'siz': chosen['siz']!,
      'dex': chosen['dex']!, 'app': chosen['app']!, 'int': chosen['int']!,
      'pow': chosen['pow']!, 'edu': chosen['edu']!,
    };
    await _runStep1Generation(fixedAttrs: fixedAttrs);
  }

  Future<void> _runStep1Generation({Map<String, int>? fixedAttrs}) async {
    final service = _getService();
    if (service == null) return;

    setState(() {
      _phase = 'loading1';
      _loadingText = fixedAttrs != null
          ? 'AI 正在基于已选属性匹配职业与技能...'
          : 'AI 正在生成属性与技能...';
      _error = null;
    });

    try {
      final result = await service.generateStep1(
        _descCtrl.text.trim(),
        _selectedOccupation?.n,
        rule: _allocRule,
        fixedAttributes: fixedAttrs,
      );
      if (!mounted) return;
      _initStep1Editors(result);
      setState(() => _phase = 'preview1');
    } catch (e) {
      setState(() {
        _phase = fixedAttrs != null ? 'destinySelect' : 'input';
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

    // 运气：天命/不含运用 _separateLuck；含运情况下 AI 不返回 luck，仍用 _separateLuck（含运时由用户在 destinySelect 选择时写入）
    if (_separateLuck > 0) {
      c.luck = _separateLuck;
    }
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

  // 处理返回逻辑：preview 阶段退到上一阶段而非销毁整个页面
  Future<bool> _handleBack() async {
    if (_phase == 'preview2') {
      setState(() => _phase = 'preview1');
      return false;
    }
    if (_phase == 'destinySelect') {
      setState(() {
        _phase = 'input';
        _destinyCandidates = [];
        _destinyPicked = -1;
      });
      return false;
    }
    if (_phase == 'preview1') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('返回会丢失已生成的内容'),
          content: const Text('确定要返回输入页吗？已生成的属性、技能、编辑内容将丢失。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定返回')),
          ],
        ),
      );
      if (confirm == true) {
        setState(() => _phase = 'input');
      }
      return false;
    }
    if (_phase == 'loading1' || _phase == 'loading2') {
      // 加载中：屏蔽返回，避免请求未完成时丢上下文
      return false;
    }
    return true; // input 阶段允许真正退出
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handleBack();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI 辅助建卡'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _handleBack();
              if (shouldPop && mounted) Navigator.of(context).pop();
            },
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case 'loading1':
      case 'loading2':
        return _buildLoading();
      case 'destinySelect':
        return _buildDestinySelect();
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
          _buildRuleEditor(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _onGeneratePressed,
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

  Widget _buildRuleEditor() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('属性分配规则', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(width: 8),
              Text(
                '（描述中含"天命N"/"X购点"会自动覆盖）',
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<AllocationMethod>(
            segments: const [
              ButtonSegment(value: AllocationMethod.destiny, label: Text('天命'), icon: Icon(Icons.casino, size: 16)),
              ButtonSegment(value: AllocationMethod.pointBuy, label: Text('购点'), icon: Icon(Icons.tune, size: 16)),
            ],
            selected: {_allocRule.method},
            onSelectionChanged: (s) => setState(() => _allocRule = _allocRule.copyWith(method: s.first)),
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
          const SizedBox(height: 8),
          if (_allocRule.method == AllocationMethod.destiny)
            Row(
              children: [
                const Text('组数 N: '),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _destinyGroupsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 3;
                      setState(() => _allocRule = _allocRule.copyWith(destinyGroups: n.clamp(1, 10)));
                    },
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                const Text('总点数 X: '),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _pointBuyTotalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(isDense: true),
                    onChanged: (v) {
                      final x = int.tryParse(v) ?? 480;
                      setState(() => _allocRule = _allocRule.copyWith(pointBuyTotal: x.clamp(40, 900)));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text('单项 ${AllocationRule.perAttributeMin}-${AllocationRule.perAttributeMax}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          Row(
            children: [
              const Text('含运: '),
              Switch(
                value: _allocRule.includeLuck,
                onChanged: (v) => setState(() => _allocRule = _allocRule.copyWith(includeLuck: v)),
              ),
              Expanded(
                child: Text(
                  _allocRule.includeLuck ? '运气参与分配' : '运气单独 3D6×5',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDestinySelect() {
    final keys = _allocRule.includeLuck
        ? ['str', 'con', 'siz', 'dex', 'app', 'int', 'pow', 'edu', 'luck']
        : ['str', 'con', 'siz', 'dex', 'app', 'int', 'pow', 'edu'];
    final labels = {
      'str': 'STR', 'con': 'CON', 'siz': 'SIZ', 'dex': 'DEX',
      'app': 'APP', 'int': 'INT', 'pow': 'POW', 'edu': 'EDU', 'luck': 'LUCK',
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_allocRule.label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '从下方 ${_destinyCandidates.length} 组中挑选一组作为角色属性',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              if (!_allocRule.includeLuck && _separateLuck > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('运气（单独投出）: $_separateLuck',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.tertiary)),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(_destinyCandidates.length, (i) {
                final g = _destinyCandidates[i];
                final selected = _destinyPicked == i;
                final sum = keys.fold<int>(0, (s, k) => s + (g[k] ?? 0));
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _destinyPicked = i),
                    child: Container(
                      width: 110,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: selected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('第 ${i + 1} 组',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ...keys.map((k) => Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(labels[k]!, style: const TextStyle(fontSize: 11)),
                                  Text('${g[k]}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              )),
                          const Divider(height: 10),
                          Text('合计 $sum',
                              style: const TextStyle(fontSize: 11), textAlign: TextAlign.end),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  final r = Random();
                  setState(() {
                    _destinyCandidates = List.generate(
                      _allocRule.destinyGroups,
                      (_) => CocDice.rollAttributeSet(r, includeLuck: _allocRule.includeLuck),
                    );
                    _destinyPicked = -1;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重新投骰'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _destinyPicked >= 0 ? _confirmDestinyAndGenerate : null,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('确定并生成职业/技能'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview1() {
    final occSpent = _getOccPointSpent();
    final intSpent = _getIntPointSpent();
    final occTotal = _getOccPointTotal();
    final intTotal = _getIntPointTotal();

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
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _phase = 'preview1'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('上一步'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
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
