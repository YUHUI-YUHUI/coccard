import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../data/character_manager.dart';
import '../data/coc_data.dart';
import '../data/skill.dart';
import '../data/allocation_rule.dart';

class CharacterCreationPage extends StatefulWidget {
  const CharacterCreationPage({super.key});

  @override
  State<CharacterCreationPage> createState() => _CharacterCreationPageState();
}

class _CharacterCreationPageState extends State<CharacterCreationPage> {
  int _currentStep = 0;

  // 基本信息
  final _nameCtrl = TextEditingController();
  final _playerCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _residenceCtrl = TextEditingController();
  final _birthplaceCtrl = TextEditingController();

  // 属性
  int str = 0, con = 0, siz = 0, dex = 0, app = 0, int_ = 0, pow = 0, edu = 0;
  int luck = 0;

  // 属性分配规则与中间状态
  AllocationRule _allocRule = AllocationRule.defaultRule;
  final TextEditingController _destinyGroupsCtrl = TextEditingController(text: '3');
  final TextEditingController _pointBuyTotalCtrl = TextEditingController(text: '480');
  List<Map<String, int>> _destinyCandidates = []; // 天命模式骰出的 N 组候选
  int _destinyPickedIndex = -1; // 选中的组下标

  // 职业
  Occupation? _selectedOccupation;

  // 技能分配
  final Map<String, int> _skills = {};
  int _occupationPointSpent = 0;
  int _interestPointSpent = 0;
  String _skillSearchQuery = '';
  final _skillSearchCtrl = TextEditingController();

  int get _occupationPointTotal {
    if (_selectedOccupation == null) return 0;
    return calcOccupationPoints(_selectedOccupation!.attr, {
      '力量': str, '体质': con, '体型': siz, '敏捷': dex,
      '外貌': app, '智力': int_, '意志': pow, '教育': edu,
    });
  }

  int get _interestPointTotal => int_ * 2;
  int get _occupationPointRemaining => _occupationPointTotal - _occupationPointSpent;
  int get _interestPointRemaining => _interestPointTotal - _interestPointSpent;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _playerCtrl.dispose();
    _ageCtrl.dispose();
    _genderCtrl.dispose();
    _residenceCtrl.dispose();
    _birthplaceCtrl.dispose();
    _skillSearchCtrl.dispose();
    _destinyGroupsCtrl.dispose();
    _pointBuyTotalCtrl.dispose();
    super.dispose();
  }

  void _applyAttributeMap(Map<String, int> a) {
    str = a['str'] ?? 0;
    con = a['con'] ?? 0;
    siz = a['siz'] ?? 0;
    dex = a['dex'] ?? 0;
    app = a['app'] ?? 0;
    int_ = a['int'] ?? 0;
    pow = a['pow'] ?? 0;
    edu = a['edu'] ?? 0;
    if (a.containsKey('luck')) luck = a['luck']!;
  }

  bool get _attributesReady {
    if (str == 0 || con == 0 || siz == 0 || dex == 0 || app == 0 || int_ == 0 || pow == 0 || edu == 0) {
      return false;
    }
    return luck > 0;
  }

  // 天命模式：骰 N 组候选
  void _rollDestinyCandidates() {
    final r = Random();
    final n = _allocRule.destinyGroups;
    setState(() {
      _destinyCandidates = List.generate(
        n,
        (_) => CocDice.rollAttributeSet(r, includeLuck: _allocRule.includeLuck),
      );
      _destinyPickedIndex = -1;
      // 清空选中状态（如果之前选过别的组）
      str = con = siz = dex = app = int_ = pow = edu = 0;
      if (!_allocRule.includeLuck) {
        luck = CocDice.rollLuck(r);
      } else {
        luck = 0;
      }
    });
  }

  void _pickDestinyGroup(int index) {
    setState(() {
      _destinyPickedIndex = index;
      _applyAttributeMap(_destinyCandidates[index]);
    });
  }

  // 购点模式：初始化或重置编辑器
  void _initPointBuy() {
    setState(() {
      str = con = siz = dex = app = int_ = pow = edu = AllocationRule.perAttributeMin;
      if (_allocRule.includeLuck) {
        luck = AllocationRule.perAttributeMin;
      } else {
        // 不含运：单独骰
        luck = CocDice.rollLuck(Random());
      }
    });
  }

  int get _pointBuySpent {
    int total = str + con + siz + dex + app + int_ + pow + edu;
    if (_allocRule.includeLuck) total += luck;
    return total;
  }

  int get _pointBuyRemaining => _allocRule.pointBuyTotal - _pointBuySpent;

  void _rerollLuckOnly() {
    setState(() => luck = CocDice.rollLuck(Random()));
  }

  // 切换分配方法：清空当前数值与候选
  void _changeMethod(AllocationMethod m) {
    setState(() {
      _allocRule = _allocRule.copyWith(method: m);
      _destinyCandidates = [];
      _destinyPickedIndex = -1;
      str = con = siz = dex = app = int_ = pow = edu = 0;
      luck = 0;
    });
  }

  void _toggleIncludeLuck(bool v) {
    setState(() {
      _allocRule = _allocRule.copyWith(includeLuck: v);
      _destinyCandidates = [];
      _destinyPickedIndex = -1;
      str = con = siz = dex = app = int_ = pow = edu = 0;
      luck = 0;
    });
  }

  void _onOccupationSelected(Occupation occ) {
    setState(() {
      _selectedOccupation = occ;
      _skills.clear();
      _occupationPointSpent = 0;
      _interestPointSpent = 0;

      // 初始化职业技能基础值
      final occSkills = occ.sk.split('，').map((s) => s.trim()).toList();
      for (final skillName in occSkills) {
        if (skillName.isNotEmpty && !skillName.startsWith('任意') && !skillName.startsWith('两项')) {
          final skillDef = SKILL_DEFS.where((s) => s.key == skillName).firstOrNull;
          if (skillDef != null) {
            _skills[skillName] = skillDef.baseHalf;
          }
        }
      }
      _skills['母语'] = edu;
    });
  }

  void _onOccupationCleared() {
    setState(() {
      _selectedOccupation = null;
      _skills.clear();
      _occupationPointSpent = 0;
      _interestPointSpent = 0;
    });
  }

  Future<void> _onFinish() async {
    final manager = context.read<CharacterManager>();

    await manager.createNewCharacter();
    if (!mounted) return;
    final c = manager.character;

    // 填入基本信息
    c.name = _nameCtrl.text.isEmpty ? '新角色' : _nameCtrl.text;
    c.player = _playerCtrl.text;
    c.age = _ageCtrl.text;
    c.gender = _genderCtrl.text;
    c.residence = _residenceCtrl.text;
    c.birthplace = _birthplaceCtrl.text;

    // 填入属性（先写 luck，让 setAttributes 内的派生计算不会重新投骰）
    c.luck = luck;
    manager.setAttributes(
      str: str, con: con, siz: siz, dex: dex,
      app: app, int_: int_, pow: pow, edu: edu,
    );

    // 如果选了职业，应用职业
    if (_selectedOccupation != null) {
      manager.applyOccupation(_selectedOccupation!);
    }

    // 应用技能分配
    for (final entry in _skills.entries) {
      c.skills[entry.key] = entry.value;
    }
    c.occupationPointSpent = _occupationPointSpent;
    c.interestPointSpent = _interestPointSpent;

    // 保存并跳转到角色卡主页
    manager.selectCharacter(c.id);
    Navigator.pushReplacementNamed(context, '/home');
  }

  bool get _hasAnyInput {
    if (_nameCtrl.text.isNotEmpty) return true;
    if (_playerCtrl.text.isNotEmpty) return true;
    if (_ageCtrl.text.isNotEmpty) return true;
    if (_genderCtrl.text.isNotEmpty) return true;
    if (_residenceCtrl.text.isNotEmpty) return true;
    if (_birthplaceCtrl.text.isNotEmpty) return true;
    if (str + con + siz + dex + app + int_ + pow + edu > 0) return true;
    if (_selectedOccupation != null) return true;
    if (_skills.isNotEmpty) return true;
    return false;
  }

  Future<bool> _handleBack() async {
    // Stepper 内非首步：返回到上一步而不是退出
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      return false;
    }
    // 首步且有输入：确认丢弃
    if (_hasAnyInput) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('放弃创建？'),
          content: const Text('已填写的内容将丢失，确定退出吗？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('继续创建')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('放弃')),
          ],
        ),
      );
      return confirm == true;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _handleBack();
        if (shouldPop && mounted) Navigator.of(context).pop();
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建角色'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final shouldPop = await _handleBack();
            if (shouldPop && mounted) Navigator.of(context).pop();
          },
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 4) {
            setState(() => _currentStep++);
          } else {
            _onFinish();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          } else {
            Navigator.pop(context);
          }
        },
        onStepTapped: (index) => setState(() => _currentStep = index),
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(_currentStep == 4 ? '完成' : '下一步'),
                ),
                const SizedBox(width: 8),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('上一步'),
                  ),
                if (_currentStep == 0)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('基本信息'),
            subtitle: Text(_nameCtrl.text.isEmpty ? '未填写' : _nameCtrl.text),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: _buildBasicInfoStep(),
          ),
          Step(
            title: Text('属性分配（${_allocRule.label}）'),
            subtitle: _attributesReady
                ? Text('$str/$con/$siz/$dex/$app/$int_/$pow/$edu  幸运:$luck')
                : const Text('未完成'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: _buildAttributeStep(),
          ),
          Step(
            title: const Text('选择职业（可选）'),
            subtitle: _selectedOccupation != null ? Text(_selectedOccupation!.n) : const Text('跳过'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: _buildOccupationStep(),
          ),
          Step(
            title: const Text('技能分配'),
            subtitle: Text(_skills.isEmpty ? '未分配' : '已分配 ${_occupationPointSpent + _interestPointSpent} 点'),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            content: _buildSkillStep(),
          ),
          Step(
            title: const Text('确认创建'),
            isActive: _currentStep >= 4,
            state: StepState.indexed,
            content: _buildConfirmStep(),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      children: [
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '角色名 *')),
        const SizedBox(height: 8),
        TextField(controller: _playerCtrl, decoration: const InputDecoration(labelText: '玩家')),
        const SizedBox(height: 8),
        TextField(controller: _ageCtrl, decoration: const InputDecoration(labelText: '年龄')),
        const SizedBox(height: 8),
        TextField(controller: _genderCtrl, decoration: const InputDecoration(labelText: '性别')),
        const SizedBox(height: 8),
        TextField(controller: _residenceCtrl, decoration: const InputDecoration(labelText: '居住地')),
        const SizedBox(height: 8),
        TextField(controller: _birthplaceCtrl, decoration: const InputDecoration(labelText: '出生地')),
      ],
    );
  }

  Widget _buildAttributeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRulePanel(),
        const SizedBox(height: 12),
        if (_allocRule.method == AllocationMethod.destiny)
          _buildDestinyArea()
        else
          _buildPointBuyArea(),
        const SizedBox(height: 12),
        if (!_allocRule.includeLuck) _buildSeparateLuck(),
      ],
    );
  }

  Widget _buildRulePanel() {
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
              Text('分配方式: ', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(width: 8),
              SegmentedButton<AllocationMethod>(
                segments: const [
                  ButtonSegment(value: AllocationMethod.destiny, label: Text('天命'), icon: Icon(Icons.casino, size: 16)),
                  ButtonSegment(value: AllocationMethod.pointBuy, label: Text('购点'), icon: Icon(Icons.tune, size: 16)),
                ],
                selected: {_allocRule.method},
                onSelectionChanged: (s) => _changeMethod(s.first),
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ],
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
                    decoration: const InputDecoration(isDense: true, hintText: '3'),
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 3;
                      setState(() => _allocRule = _allocRule.copyWith(destinyGroups: n.clamp(1, 10)));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('天命 ${_allocRule.destinyGroups}: 骰 ${_allocRule.destinyGroups} 组，挑一组',
                      style: const TextStyle(fontSize: 12)),
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
                    decoration: const InputDecoration(isDense: true, hintText: '480'),
                    onChanged: (v) {
                      final x = int.tryParse(v) ?? 480;
                      setState(() => _allocRule = _allocRule.copyWith(pointBuyTotal: x.clamp(40, 900)));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('购点 ${_allocRule.pointBuyTotal}: 单项 ${AllocationRule.perAttributeMin}-${AllocationRule.perAttributeMax}',
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('含运: '),
              Switch(
                value: _allocRule.includeLuck,
                onChanged: _toggleIncludeLuck,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _allocRule.includeLuck ? '运气和8项属性使用同一机制分配' : '运气单独由 3D6×5 投出',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDestinyArea() {
    if (_destinyCandidates.isEmpty) {
      return ElevatedButton.icon(
        onPressed: _rollDestinyCandidates,
        icon: const Icon(Icons.casino),
        label: Text('投骰生成 ${_allocRule.destinyGroups} 组候选'),
      );
    }
    final keys = _allocRule.includeLuck
        ? ['str', 'con', 'siz', 'dex', 'app', 'int', 'pow', 'edu', 'luck']
        : ['str', 'con', 'siz', 'dex', 'app', 'int', 'pow', 'edu'];
    final labels = {
      'str': 'STR', 'con': 'CON', 'siz': 'SIZ', 'dex': 'DEX',
      'app': 'APP', 'int': 'INT', 'pow': 'POW', 'edu': 'EDU', 'luck': 'LUCK',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('点击下方某组以选择', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_destinyCandidates.length, (i) {
              final g = _destinyCandidates[i];
              final selected = _destinyPickedIndex == i;
              final sum = keys.fold<int>(0, (s, k) => s + (g[k] ?? 0));
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _pickDestinyGroup(i),
                  child: Container(
                    width: 92,
                    padding: const EdgeInsets.all(8),
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
                        Text('第 ${i + 1} 组', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        ...keys.map((k) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(labels[k]!, style: const TextStyle(fontSize: 11)),
                                Text('${g[k]}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            )),
                        const Divider(height: 8),
                        Text('合计 $sum', style: const TextStyle(fontSize: 11), textAlign: TextAlign.end),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _rollDestinyCandidates,
          icon: const Icon(Icons.refresh),
          label: const Text('重新投骰'),
        ),
      ],
    );
  }

  Widget _buildPointBuyArea() {
    if (str == 0 && con == 0) {
      return ElevatedButton.icon(
        onPressed: _initPointBuy,
        icon: const Icon(Icons.tune),
        label: const Text('开始购点'),
      );
    }
    final remaining = _pointBuyRemaining;
    final overspent = remaining < 0;
    final keys = ['str', 'con', 'siz', 'dex', 'app', 'int', 'pow', 'edu'];
    final labels = {
      'str': '力量 STR', 'con': '体质 CON', 'siz': '体型 SIZ', 'dex': '敏捷 DEX',
      'app': '外貌 APP', 'int': '智力 INT', 'pow': '意志 POW', 'edu': '教育 EDU',
    };
    int getAttr(String k) {
      switch (k) {
        case 'str': return str;
        case 'con': return con;
        case 'siz': return siz;
        case 'dex': return dex;
        case 'app': return app;
        case 'int': return int_;
        case 'pow': return pow;
        case 'edu': return edu;
      }
      return 0;
    }
    void setAttr(String k, int v) {
      setState(() {
        switch (k) {
          case 'str': str = v; break;
          case 'con': con = v; break;
          case 'siz': siz = v; break;
          case 'dex': dex = v; break;
          case 'app': app = v; break;
          case 'int': int_ = v; break;
          case 'pow': pow = v; break;
          case 'edu': edu = v; break;
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: overspent
                ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.4)
                : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                '剩余: $remaining / ${_allocRule.pointBuyTotal}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: overspent ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (overspent)
                Text('已超支 ${-remaining} 点', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...keys.map((k) => _pointBuyRow(labels[k]!, getAttr(k), (v) => setAttr(k, v))),
        if (_allocRule.includeLuck)
          _pointBuyRow('运气 LUCK', luck, (v) => setState(() => luck = v)),
      ],
    );
  }

  Widget _pointBuyRow(String label, int value, void Function(int) onChanged) {
    const min = AllocationRule.perAttributeMin;
    const max = AllocationRule.perAttributeMax;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 14))),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: value > min ? () => onChanged(value - 5) : null,
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 50,
            child: Text(
              '$value',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: value < max ? () => onChanged(value + 5) : null,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Slider(
              value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: (max - min) ~/ 5,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparateLuck() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('运气 (3D6×5): ', style: TextStyle(color: Theme.of(context).colorScheme.tertiary)),
          Text(
            luck > 0 ? '$luck' : '未投骰',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新投骰运气',
            onPressed: _rerollLuckOnly,
          ),
        ],
      ),
    );
  }

  Widget _buildOccupationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('从列表中选择职业（可跳过）', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        if (_selectedOccupation != null)
          Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
              title: Text(_selectedOccupation!.n),
              subtitle: Text('信用: ${_selectedOccupation!.min}-${_selectedOccupation!.max} | ${_selectedOccupation!.attr}'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _onOccupationCleared,
              ),
            ),
          )
        else
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: OCCUPATIONS.length,
              itemBuilder: (context, index) {
                final occ = OCCUPATIONS[index];
                return ListTile(
                  title: Text(occ.n),
                  subtitle: Text('${occ.attr} | 信用 ${occ.min}-${occ.max}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _onOccupationSelected(occ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSkillStep() {
    if (!_attributesReady) {
      return Text(
        '请先完成属性分配',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }

    final totalSpent = _occupationPointSpent + _interestPointSpent;
    final occSkills = _selectedOccupation?.sk.split('，').map((s) => s.trim()).toSet() ?? {};

    // 过滤技能列表
    List<SkillDef> filteredSkills = SKILL_DEFS.where((skill) {
      if (_skillSearchQuery.isNotEmpty) {
        return skill.name.contains(_skillSearchQuery);
      }
      return true;
    }).toList();

    // 职业技能排在前面
    if (_skillSearchQuery.isEmpty) {
      filteredSkills.sort((a, b) {
        final aIsOcc = occSkills.contains(a.key);
        final bIsOcc = occSkills.contains(b.key);
        if (aIsOcc && !bIsOcc) return -1;
        if (!aIsOcc && bIsOcc) return 1;
        return 0;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 点数显示
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('职业点数', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                        Text(
                          '$_occupationPointRemaining / $_occupationPointTotal',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('兴趣点数', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.tertiary)),
                        Text(
                          '$_interestPointRemaining / $_interestPointTotal',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.tertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_selectedOccupation == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '未选择职业，仅可使用兴趣点数',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 搜索框
        TextField(
          controller: _skillSearchCtrl,
          decoration: InputDecoration(
            hintText: '搜索技能...',
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: _skillSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _skillSearchCtrl.clear();
                      setState(() => _skillSearchQuery = '');
                    },
                  )
                : null,
          ),
          onChanged: (v) => setState(() => _skillSearchQuery = v),
        ),
        const SizedBox(height: 8),

        // 技能列表
        SizedBox(
          height: 350,
          child: ListView.builder(
            itemCount: filteredSkills.length,
            itemBuilder: (context, index) {
              final skill = filteredSkills[index];
              final currentValue = _skills[skill.key] ?? skill.baseHalf;
              final isOcc = occSkills.contains(skill.key);
              final addedPoints = currentValue - skill.baseHalf;

              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                color: isOcc ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
                child: ListTile(
                  dense: true,
                  leading: isOcc
                      ? Icon(Icons.work, size: 16, color: Theme.of(context).colorScheme.primary)
                      : null,
                  title: Text(skill.name),
                  subtitle: Text(_getCategoryName(skill.category), style: const TextStyle(fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (addedPoints > 0)
                        Text('+$addedPoints', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.tertiary)),
                      const SizedBox(width: 4),
                      Text(
                        '$currentValue%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: addedPoints > 0
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 16),
                    ],
                  ),
                  onTap: () => _showSkillAllocDialog(skill, currentValue, isOcc),
                ),
              );
            },
          ),
        ),

        if (totalSpent > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '已分配: 职业 $_occupationPointSpent 点 + 兴趣 $_interestPointSpent 点 = 共 $totalSpent 点',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
      ],
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

  void _showSkillAllocDialog(SkillDef skill, int currentValue, bool isOccSkill) {
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
                Text('分别投入职业点数和兴趣点数:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_selectedOccupation != null) ...[
                  Row(
                    children: [
                      Text('职业点数 (剩余 $_occupationPointRemaining): '),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: occCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '0', isDense: true),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Text('兴趣点数 (剩余 $_interestPointRemaining): '),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: intCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '0', isDense: true),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '将增加: ${((int.tryParse(occCtrl.text) ?? 0) + (int.tryParse(intCtrl.text) ?? 0))}%',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
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

                if (occAdd > _occupationPointRemaining) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('职业点数不足！')),
                  );
                  return;
                }
                if (intAdd > _interestPointRemaining) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('兴趣点数不足！')),
                  );
                  return;
                }
                if (occAdd == 0 && intAdd == 0) {
                  Navigator.pop(context);
                  return;
                }

                setState(() {
                  _skills[skill.key] = currentValue + occAdd + intAdd;
                  _occupationPointSpent += occAdd;
                  _interestPointSpent += intAdd;
                });
                Navigator.pop(context);
              },
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmStep() {
    final totalSpent = _occupationPointSpent + _interestPointSpent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('确认信息', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                _confirmRow('角色名', _nameCtrl.text.isEmpty ? '新角色' : _nameCtrl.text),
                _confirmRow('玩家', _playerCtrl.text.isEmpty ? '—' : _playerCtrl.text),
                _confirmRow('职业', _selectedOccupation?.n ?? '未选择'),
                const Divider(),
                const Text('属性', style: TextStyle(fontWeight: FontWeight.bold)),
                _confirmRow('分配方式', _allocRule.label),
                _confirmRow('力量/体质/体型/敏捷', '$str / $con / $siz / $dex'),
                _confirmRow('外貌/智力/意志/教育', '$app / $int_ / $pow / $edu'),
                _confirmRow('运气', '$luck'),
                const Divider(),
                Text('技能分配', style: TextStyle(fontWeight: FontWeight.bold)),
                _confirmRow('已分配点数', '$totalSpent 点（职业 $_occupationPointSpent + 兴趣 $_interestPointSpent）'),
                _confirmRow('技能数量', '${_skills.length} 项'),
                const SizedBox(height: 8),
                Text(
                  '点击"完成"后将创建角色卡并保存。',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
