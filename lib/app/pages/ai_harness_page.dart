import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/character_manager.dart';
import '../data/coc_data.dart';
import '../data/skill.dart';
import '../services/deepseek_harness.dart';
import '../services/deepseek_service.dart';
import '../setting/app_pref.dart';

/// DeepSeek Harness · AI 助手
///
/// 应用内的 Agent 模块：支持资料问答（本地规则知识库检索）、
/// 场景描述生成行动、AI 建卡（可一键保存为新角色）与自由对话。
class AiHarnessPage extends StatefulWidget {
  const AiHarnessPage({super.key});

  @override
  State<AiHarnessPage> createState() => _AiHarnessPageState();
}

class _HarnessMessage {
  final bool fromUser;
  final String text;
  final List<HarnessToolStep> steps;
  final HarnessResult? result;

  const _HarnessMessage({
    required this.fromUser,
    required this.text,
    this.steps = const [],
    this.result,
  });
}

class _AiHarnessPageState extends State<AiHarnessPage> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_HarnessMessage> _messages = [];

  HarnessMode? _mode; // null = 自动判断
  bool _loading = false;
  String? _apiKey;

  static const _modeLabels = {
    null: '自动判断',
    HarnessMode.research: '资料问答',
    HarnessMode.sceneAction: '场景行动',
    HarnessMode.characterCreate: 'AI 建卡',
  };

  static const _modeIcons = {
    null: Icons.auto_awesome,
    HarnessMode.research: Icons.menu_book_outlined,
    HarnessMode.sceneAction: Icons.theater_comedy_outlined,
    HarnessMode.characterCreate: Icons.style_outlined,
  };

  static const _modeDescriptions = {
    null: '根据你输入的内容自动选择工具',
    HarnessMode.research: '查阅内置规则资料，回答检定、理智、战斗等规则问题',
    HarnessMode.sceneAction: '粘贴场景描述，生成调查员行动、KP 推进建议与检定方案',
    HarnessMode.characterCreate: '描述角色，直接生成属性、技能、背景与物品',
  };

  static const _suggestions = {
    HarnessMode.research: [
      '奖励骰和惩罚骰怎么判定？',
      '临时疯狂怎么触发？',
      '幕间成长检定怎么做？',
      '大成功和大失败怎么判定？',
    ],
    HarnessMode.sceneAction: [
      '调查员走进废弃的疯人院，灯突然熄灭，走廊尽头传来脚步声，还有低语声…',
      '他们在图书馆找到一本被撕掉关键页的日记，最后一页写着"它已经醒了"…',
      '夜里调查员被敲门声惊醒，门外自称是失踪者的妻子，声音却有些不对…',
    ],
    HarnessMode.characterCreate: [
      '来自阿卡姆的大学教授，研究古代神话，性格内向但学识渊博，曾多次参与考古探险',
      '退役军医，战争后回到故乡开诊所，总做同一个噩梦',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final appPref = AppPreferences(prefs);
    if (!mounted) return;
    setState(() => _apiKey = appPref.getDeepseekApiKey());
  }

  DeepseekHarness? _getHarness() {
    if (_apiKey == null || _apiKey!.isEmpty) return null;
    return DeepseekHarness(ai: AiService(apiKey: _apiKey!));
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _inputCtrl.text).trim();
    if (text.isEmpty || _loading) return;
    _inputCtrl.clear();

    await _loadApiKey();
    if (!mounted) return;
    final harness = _getHarness();
    if (harness == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请先在设置页配置 DeepSeek API Key'),
          action: SnackBarAction(
            label: '去设置',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _messages.add(_HarnessMessage(fromUser: true, text: text));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final result = await harness.run(input: text, mode: _mode);
      if (!mounted) return;
      setState(() {
        _messages.add(_HarnessMessage(
          fromUser: false,
          text: result.answer,
          steps: result.steps,
          result: result,
        ));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成失败：$e')),
      );
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _applyCharacter(Step1Result step1, Step2Result step2) async {
    final manager = context.read<CharacterManager>();
    await manager.createNewCharacter();
    final c = manager.character;

    c.name = step1.name.isEmpty ? '新角色' : step1.name;
    c.age = step1.age;
    c.gender = step1.gender;
    c.residence = step1.residence;
    c.birthplace = step1.birthplace;

    manager.setAttributes(
      str: step1.attributes['str'] ?? 50,
      con: step1.attributes['con'] ?? 50,
      siz: step1.attributes['siz'] ?? 50,
      dex: step1.attributes['dex'] ?? 50,
      app: step1.attributes['app'] ?? 50,
      int_: step1.attributes['int'] ?? 50,
      pow: step1.attributes['pow'] ?? 50,
      edu: step1.attributes['edu'] ?? 50,
    );

    if (step1.occId != null) {
      final occ = OCCUPATIONS.where((o) => o.id == step1.occId).firstOrNull;
      if (occ != null) manager.applyOccupation(occ);
    }

    int occSpent = 0;
    int intSpent = 0;
    for (final entry in step1.skills.entries) {
      occSpent += entry.value.occ;
      intSpent += entry.value.interest;
      if (entry.key == '母语') {
        // 母语基础值即教育值，避免被 0 覆盖
        c.skills['母语'] = c.edu;
        continue;
      }
      final skillDef = SKILL_DEFS.where((s) => s.key == entry.key).firstOrNull;
      c.skills[entry.key] =
          (skillDef?.baseHalf ?? 0) + entry.value.occ + entry.value.interest;
    }
    c.occupationPointSpent = occSpent;
    c.interestPointSpent = intSpent;

    manager.updateBackstory(step2.backstory);
    manager.updateAppearance(step2.appearance);
    manager.updateItems(step2.items);
    manager.updateFinance(cash: step2.cash);
    manager.selectCharacter(c.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已保存角色「${c.name}」')),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DeepSeek Harness · AI 助手'),
        actions: [
          IconButton(
            tooltip: '清空对话',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _messages.isEmpty
                ? null
                : () => setState(() => _messages.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildModeSelector(),
          const Divider(height: 1),
          Expanded(
            child: _messages.isEmpty ? _buildWelcome() : _buildChatList(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final mode in [
            null,
            HarnessMode.research,
            HarnessMode.sceneAction,
            HarnessMode.characterCreate,
          ]) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: Key('harness_mode_${mode?.name ?? 'auto'}'),
                avatar: Icon(_modeIcons[mode], size: 18),
                label: Text(_modeLabels[mode]!),
                selected: _mode == mode,
                onSelected: _loading
                    ? null
                    : (_) => setState(() => _mode = mode),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    final scheme = Theme.of(context).colorScheme;
    final suggestions = _mode == null ? null : _suggestions[_mode];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(Icons.smart_toy_outlined,
                          color: scheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'DeepSeek Harness',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '应用内的 Agent 模块：查阅规则资料、根据场景生成行动、AI 建卡，全部在对话里完成。',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final mode in [
                      null,
                      HarnessMode.research,
                      HarnessMode.sceneAction,
                      HarnessMode.characterCreate,
                    ])
                      Tooltip(
                        message: _modeDescriptions[mode]!,
                        child: Chip(
                          avatar: Icon(_modeIcons[mode], size: 16),
                          label: Text(_modeLabels[mode]!),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (suggestions != null) ...[
          const SizedBox(height: 16),
          Text(
            '试试这些${_modeLabels[_mode]}示例',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final s in suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ActionChip(
                label: Text(s, maxLines: 2, overflow: TextOverflow.ellipsis),
                onPressed: _loading ? null : () => _send(s),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _messages.length) return _buildThinking();
        return _buildMessage(_messages[index]);
      },
    );
  }

  Widget _buildThinking() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Harness 正在执行工具…',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(_HarnessMessage message) {
    final scheme = Theme.of(context).colorScheme;
    if (message.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: SelectableText(message.text),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.steps.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final step in message.steps)
                    Chip(
                      avatar: Text(step.icon),
                      label: Text(step.title),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            SelectableText(
              message.text,
              style: const TextStyle(height: 1.5),
            ),
            if (message.result?.step1 != null && message.result?.step2 != null)
              _buildCharacterActions(message.result!),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterActions(HarnessResult result) {
    final step1 = result.step1!;
    final step2 = result.step2!;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.style_outlined,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text('角色卡已就绪：${step1.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('harness_open_ai_character'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('AI 建卡页继续编辑'),
                  onPressed: () => Navigator.pushNamed(context, '/ai_character'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('harness_save_character'),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('保存为新角色'),
                  onPressed: () => _applyCharacter(step1, step2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                minLines: 1,
                maxLines: 4,
                enabled: !_loading,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: _mode == null
                      ? '提问规则 / 描述场景 / 描述角色…'
                      : '${_modeLabels[_mode]}：输入内容…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _loading ? null : _send,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
