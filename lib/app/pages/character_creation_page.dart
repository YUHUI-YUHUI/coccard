import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../data/character.dart';
import '../data/character_manager.dart';
import '../data/coc_data.dart';

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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _playerCtrl.dispose();
    _ageCtrl.dispose();
    _genderCtrl.dispose();
    _residenceCtrl.dispose();
    _birthplaceCtrl.dispose();
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

  void _onFinish() {
    final manager = context.read<CharacterManager>();
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

    // 保存并返回
    manager.selectCharacter(c.id);
    Navigator.pop(context);
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
          if (_currentStep < 3) {
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
                  child: Text(_currentStep == 3 ? '完成' : '下一步'),
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
            title: const Text('确认创建'),
            isActive: _currentStep >= 3,
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
          const Text('投骰公式: 3D6×5（投3个六面骰相加再乘5）', style: TextStyle(color: Colors.grey))
        else
          Text('平均值: $avg（{$total÷8}）', style: const TextStyle(color: Colors.grey)),
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
        const Text('从列表中选择职业（可跳过）', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        if (_selectedOccupation != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.blue),
              title: Text(_selectedOccupation!.n),
              subtitle: Text('信用: ${_selectedOccupation!.min}-${_selectedOccupation!.max} | ${_selectedOccupation!.attr}'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedOccupation = null),
              ),
            ),
          )
        else
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
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
                  onTap: () => setState(() => _selectedOccupation = occ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildConfirmStep() {
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
                const SizedBox(height: 8),
                const Text(
                  '点击"完成"后将自动填入当前角色卡。',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
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
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}