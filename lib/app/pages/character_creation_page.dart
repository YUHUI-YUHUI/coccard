import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../data/character_manager.dart';
import '../data/coc_data.dart';
import '../data/skill.dart';

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
    super.dispose();
  }

  void _rollAllAttributes() {
    final r = Random();
    setState(() {
      str = _roll3d6x5(r);
      con = _roll3d6x5(r);
      siz = _roll3d6x5(r);
      dex = _roll3d6x5(r);
      app = _roll3d6x5(r);
      int_ = _roll3d6x5(r);
      pow = _roll3d6x5(r);
      edu = _roll3d6x5(r);
    });
  }

  int _roll3d6x5(Random r) {
    return ((r.nextInt(6) + 1) + (r.nextInt(6) + 1) + (r.nextInt(6) + 1)) * 5;
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
    final c = manager.character;

    // 填入基本信息
    c.name = _nameCtrl.text.isEmpty ? '新角色' : _nameCtrl.text;
    c.player = _playerCtrl.text;
    c.age = _ageCtrl.text;
    c.gender = _genderCtrl.text;
    c.residence = _residenceCtrl.text;
    c.birthplace = _birthplaceCtrl.text;

    // 填入属性
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建角色'),
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
            title: const Text('属性投骰'),
            subtitle: str > 0 ? Text('$str/$con/$siz/$dex/$app/$int_/$pow/$edu') : const Text('未投骰'),
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
    final total = str + con + siz + dex + app + int_ + pow + edu;
    final avg = total ~/ 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (str == 0)
          Text('投骰公式: 3D6×5（投3个六面骰相加再乘5）', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
        else
          Text('平均值: $avg（{$total÷8}）', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        if (str == 0)
          ElevatedButton.icon(
            onPressed: _rollAllAttributes,
            icon: const Icon(Icons.casino),
            label: const Text('投骰'),
          )
        else ...[
          _attrRow('力量 (STR)', str),
          _attrRow('体质 (CON)', con),
          _attrRow('体型 (SIZ)', siz),
          _attrRow('敏捷 (DEX)', dex),
          _attrRow('外貌 (APP)', app),
          _attrRow('智力 (INT)', int_),
          _attrRow('意志 (POW)', pow),
          _attrRow('教育 (EDU)', edu),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _rollAllAttributes,
            icon: const Icon(Icons.refresh),
            label: const Text('重新投骰'),
          ),
        ],
      ],
    );
  }

  Widget _attrRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          SizedBox(
            width: 60,
            child: Text(
              value.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.right,
            ),
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
    if (str == 0) {
      return Text(
        '请先完成属性投骰',
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
                _confirmRow('力量/体质/体型/敏捷', '$str / $con / $siz / $dex'),
                _confirmRow('外貌/智力/意志/教育', '$app / $int_ / $pow / $edu'),
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
