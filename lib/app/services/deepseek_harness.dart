import '../data/allocation_rule.dart';
import '../data/rule_knowledge.dart';
import 'deepseek_service.dart';

/// DeepSeek Harness 功能模式。
///
/// - [research]：查阅资料——本地规则知识库检索 + 大模型解答。
/// - [sceneAction]：根据场景描述生成行动建议（守秘人助手）。
/// - [characterCreate]：AI 建卡，复用 [AiService] 的两阶段生成。
/// - [chat]：自由对话兜底。
enum HarnessMode { research, sceneAction, characterCreate, chat }

/// 一次工具调用过程的展示信息，UI 用它渲染"Harness 正在做什么"。
class HarnessToolStep {
  final String icon;
  final String title;
  final List<String> details;

  const HarnessToolStep({
    required this.icon,
    required this.title,
    this.details = const [],
  });
}

/// Harness 的一次完整执行结果。
class HarnessResult {
  final HarnessMode mode;
  final List<HarnessToolStep> steps;
  final String answer;

  /// 资料问答命中/参考的内置规则条目。
  final List<RuleKnowledgeEntry> referenceHits;

  /// AI 建卡模式下的中间结果，UI 可用来提供"继续编辑 / 直接保存"。
  final Step1Result? step1;
  final Step2Result? step2;

  const HarnessResult({
    required this.mode,
    required this.steps,
    required this.answer,
    this.referenceHits = const [],
    this.step1,
    this.step2,
  });
}

/// 应用内"DeepSeek Harness"：一个轻量 Agent 模块。
///
/// 借鉴 dsh（DeepSeek Harness）"一切皆插件/工具"的思路，在 Flutter 应用内
/// 实现一个带工具路由的执行环：
/// 1. 判断用户请求属于哪个能力（资料检索 / 场景行动 / AI 建卡 / 自由对话）；
/// 2. 执行本地工具（检索内置规则知识库、调用既有建卡服务）；
/// 3. 把工具结果作为上下文交给 DeepSeek 生成最终回答。
class DeepseekHarness {
  final AiService ai;

  DeepseekHarness({required this.ai});

  /// 根据关键词判断请求意图，命中不了则走自由对话。
  HarnessMode detectMode(String input) {
    final text = input.trim();
    if (text.isEmpty) return HarnessMode.chat;

    const characterHints = [
      '建卡', '角色卡', '创建角色', '生成角色', '车卡', '做张卡',
      '新角色', '人物卡', '生成一个角色', '做个角色',
    ];
    if (characterHints.any(text.contains)) return HarnessMode.characterCreate;
    if (text.contains('角色') &&
        (text.contains('创建') ||
            text.contains('生成') ||
            text.contains('建') ||
            text.contains('做') ||
            text.contains('车'))) {
      return HarnessMode.characterCreate;
    }

    const sceneHints = [
      '场景', '接下来', '怎么办', '发生了什么', '遭遇', '敌人',
      '线索', '行动建议', '推进', '这段剧情', '给个行动', '场景描述',
    ];
    if (sceneHints.any(text.contains)) return HarnessMode.sceneAction;

    const researchHints = [
      '规则', '检定', '奖励骰', '惩罚骰', '理智', '疯狂', '技能',
      '战斗', '伤害', '成长', '幸运', 'san', 'hp', 'mp', '大成功',
      '大失败', 'push', '孤注', '规则书', '资料', '查询', '查一下',
    ];
    if (researchHints.any(text.toLowerCase().contains)) {
      return HarnessMode.research;
    }
    return HarnessMode.chat;
  }

  /// 执行一次 Harness 请求。
  ///
  /// [mode] 为空时使用 [detectMode] 自动路由。
  Future<HarnessResult> run({
    required String input,
    HarnessMode? mode,
  }) async {
    final effectiveMode = mode ?? detectMode(input);
    switch (effectiveMode) {
      case HarnessMode.research:
        return _runResearch(input);
      case HarnessMode.sceneAction:
        return _runSceneAction(input);
      case HarnessMode.characterCreate:
        return _runCharacterCreate(input);
      case HarnessMode.chat:
        return _runChat(input);
    }
  }

  Future<HarnessResult> _runResearch(String input) async {
    final query = input.trim();
    final hits = searchRuleKnowledge(query, limit: 6);

    final knowledge = hits.isEmpty
        ? '（本地知识库未命中任何条目）'
        : hits.map((e) => e.toContextString()).join('\n\n---\n\n');
    final hitNote = hits.isEmpty
        ? '本地内置资料没有命中，以下为通用解答，如需精确规则请查规则书原文。'
        : '本地命中 ${hits.length} 条规则资料，回答请以这些资料为主要依据。';

    final systemPrompt = '''
你是克苏鲁的呼唤（COC）第七版 TRPG 的规则助理，负责查阅资料并回答规则问题。

$hitNote

回答要求：
- 先直接给出结论，再分点说明依据。
- 引用资料时标注条目名，例如【D100 检定与成功等级】。
- 如果资料不足以回答，明确说明"内置资料未覆盖，建议查阅守秘人规则书原文"，并给出最接近的条目作为参考。
- 涉及守秘人自由裁量的内容，提示"以守秘人裁定为准"。
- 使用简体中文，保持简洁。

## 内置规则资料
$knowledge
''';

    final answer = await ai.chat(
      systemPrompt: systemPrompt,
      userPrompt: '问题：$query',
    );

    return HarnessResult(
      mode: HarnessMode.research,
      steps: [
        HarnessToolStep(
          icon: '📚',
          title: hits.isEmpty ? '规则资料检索（无命中）' : '规则资料检索',
          details: hits.isEmpty
              ? const ['本地知识库未命中，转为通用解答']
              : hits.map((e) => '${e.category} · ${e.title}').toList(),
        ),
      ],
      answer: answer,
      referenceHits: hits,
    );
  }

  Future<HarnessResult> _runSceneAction(String input) async {
    const systemPrompt = '''
你是克苏鲁的呼唤（COC）第七版 TRPG 的资深守秘人（KP）助手，负责根据场景描述生成行动建议。
你不需要直接推进剧情，而是为守秘人提供可用、具体、有戏剧张力的选项。

请按以下结构输出：
1. 场景要点：梳理关键信息、氛围与潜在危险。
2. 调查员可选行动：给出 4-6 个具体行动方向，说明各自可能用到的技能/属性检定。
3. 守秘人推进建议：给出 2-3 个推动剧情或制造紧张感的手段（NPC 反应、突发事件、线索埋点）。
4. 可能的检定与后果：列出建议检定（含难度建议）以及失败时可能的结果。
5. 隐藏线索与后续发展：提供 1-2 条可留待后用的线索和可能的剧情走向。

要求：
- 行动要具体到"做什么、怎么做、可能用什么检定"，不要泛泛而谈。
- 符合克苏鲁氛围：未知、不安、代价、慢热。
- 使用简体中文，用 Markdown 分节输出。
''';

    final answer = await ai.chat(
      systemPrompt: systemPrompt,
      userPrompt: '场景描述：\n$input',
      temperature: 0.9,
      maxTokens: 2048,
    );

    return HarnessResult(
      mode: HarnessMode.sceneAction,
      steps: const [
        HarnessToolStep(
          icon: '🎭',
          title: '场景行动生成',
          details: ['场景要点梳理', '调查员行动建议', '守秘人推进建议', '检定与后果'],
        ),
      ],
      answer: answer,
    );
  }

  Future<HarnessResult> _runCharacterCreate(String input) async {
    final description = input.trim();
    final rule = AllocationRule.parseFromDescription(description);

    final step1 = await ai.generateStep1(
      description,
      null,
      rule: rule ?? AllocationRule.defaultRule,
    );
    final step2 = await ai.generateStep2(description, step1);

    final topSkills = step1.skills.entries
        .map((e) => (name: e.key, total: e.value.occ + e.value.interest))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    final skillText = topSkills
        .take(6)
        .map((e) => '${e.name}${e.total}')
        .join('、');

    final answer = '''
角色已生成：**${step1.name}**（${step1.gender}，${step1.age}岁，${step1.residence}）

- 职业：${step1.occupation}
- 属性：力量${step1.attributes['str']} 体质${step1.attributes['con']} 体型${step1.attributes['siz']} 敏捷${step1.attributes['dex']} 外貌${step1.attributes['app']} 智力${step1.attributes['int']} 意志${step1.attributes['pow']} 教育${step1.attributes['edu']}
- 重点技能：$skillText
- 背景与外貌：${step2.backstory.length > 60 ? '${step2.backstory.substring(0, 60)}…' : step2.backstory}
- 随身现金：${step2.cash}；随身物品 ${step2.items.length} 件

点击下方按钮，可以继续在 AI 建卡页编辑，或直接保存为新角色。
''';

    return HarnessResult(
      mode: HarnessMode.characterCreate,
      steps: const [
        HarnessToolStep(
          icon: '🎴',
          title: 'AI 建卡 · 属性与技能',
          details: ['生成属性、职业与技能分配'],
        ),
        HarnessToolStep(
          icon: '📜',
          title: 'AI 建卡 · 背景与物品',
          details: ['生成背景故事、外貌、现金与物品'],
        ),
      ],
      answer: answer,
      step1: step1,
      step2: step2,
    );
  }

  Future<HarnessResult> _runChat(String input) async {
    const systemPrompt = '''
你是克苏鲁的呼唤（COC）第七版 TRPG 助手，擅长规则答疑、场景设计、建卡建议与跑团流程支持。
回答使用简体中文，尽量具体、可操作；涉及规则裁决时提示"以守秘人裁定为准"。
''';
    final answer = await ai.chat(
      systemPrompt: systemPrompt,
      userPrompt: input,
      maxTokens: 1024,
    );
    return HarnessResult(
      mode: HarnessMode.chat,
      steps: const [
        HarnessToolStep(
          icon: '💬',
          title: '自由对话',
          details: ['DeepSeek 直接回答'],
        ),
      ],
      answer: answer,
    );
  }
}
