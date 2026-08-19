import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/skill.dart';
import '../data/coc_data.dart';
import '../data/character.dart';
import '../data/allocation_rule.dart';

enum AiProvider {
  deepseek('DeepSeek', 'https://api.deepseek.com/chat/completions', 'deepseek-chat');

  final String label;
  final String url;
  final String model;
  const AiProvider(this.label, this.url, this.model);
}

class SkillAlloc {
  final int occ;
  final int interest;
  SkillAlloc({this.occ = 0, this.interest = 0});
}

class Step1Result {
  String name;
  String age;
  String gender;
  String residence;
  String birthplace;
  String occupation;
  int? occId;
  Map<String, int> attributes;
  Map<String, SkillAlloc> skills;

  Step1Result({
    this.name = '',
    this.age = '',
    this.gender = '',
    this.residence = '',
    this.birthplace = '',
    this.occupation = '',
    this.occId,
    Map<String, int>? attributes,
    Map<String, SkillAlloc>? skills,
  })  : attributes = attributes ?? {},
        skills = skills ?? {};
}

class Step2Result {
  String backstory;
  String appearance;
  List<CharacterItem> items;
  int cash;

  Step2Result({
    this.backstory = '',
    this.appearance = '',
    List<CharacterItem>? items,
    this.cash = 0,
  }) : items = items ?? [];
}

class AiService {
  final String apiKey;
  final AiProvider provider;
  final http.Client? _client;
  static const _maxRetries = 3;

  AiService({required this.apiKey, this.provider = AiProvider.deepseek, http.Client? client})
      : _client = client;

  /// 生成 Step1：属性 + 职业 + 技能。
  /// - [rule] 决定属性约束（天命/购点）。
  /// - [fixedAttributes] 若非空，AI 不再生成属性，而是基于这组固定属性补完其余字段。
  ///   主要用于天命模式（属性本地骰好后让 AI 仅做职业/技能匹配）。
  Future<Step1Result> generateStep1(
    String description,
    String? occupation, {
    AllocationRule? rule,
    Map<String, int>? fixedAttributes,
  }) async {
    final effectiveRule = rule ?? AllocationRule.defaultRule;
    final systemPrompt = _buildStep1SystemPrompt(effectiveRule, fixedAttributes);
    final userPrompt = _buildStep1UserPrompt(description, occupation, effectiveRule, fixedAttributes);
    // 仅当调用方显式传入规则时才强制规则约束（保持向后兼容）
    final enforceRule = rule != null;

    Exception? lastError;
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await _callApi(systemPrompt, userPrompt);
        var result = _parseStep1Response(response);
        // 固定属性模式：忽略 AI 返回的 attributes，强制使用调用方提供的
        if (fixedAttributes != null) {
          result.attributes = Map.of(fixedAttributes);
        }
        // 后处理：把 AI 没用完的技能点本地补到通用技能上
        _autoFillRemainingSkillPoints(result);
        final valid = _validateStep1(result, effectiveRule, enforceRule: enforceRule);
        if (valid) return result;
        lastError = Exception('生成数据校验失败（属性或技能点未满足规则）');
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }
    throw lastError ?? Exception('生成失败，已重试 $_maxRetries 次');
  }

  /// 把 AI 没分配完的职业点/兴趣点本地补到通用技能上，确保点数用完。
  /// 单技能合计上限 90%（基础值 + occ + int）。
  static const _fillerSkills = [
    '聆听', '侦查', '心理学', '图书馆', '急救',
    '说服', '话术', '魅惑', '潜行', '闪避',
    '攀爬', '游泳', '跳跃', '投掷', '导航',
    '自然', '历史', '科学', '神秘学',
  ];
  static const _skillCap = 90;

  void _autoFillRemainingSkillPoints(Step1Result result) {
    // 计算职业点上限
    int occTotal = 0;
    if (result.occId != null) {
      final occ = OCCUPATIONS.where((o) => o.id == result.occId).firstOrNull;
      if (occ != null) {
        occTotal = calcOccupationPoints(occ.attr, {
          '力量': result.attributes['str'] ?? 50,
          '体质': result.attributes['con'] ?? 50,
          '体型': result.attributes['siz'] ?? 50,
          '敏捷': result.attributes['dex'] ?? 50,
          '外貌': result.attributes['app'] ?? 50,
          '智力': result.attributes['int'] ?? 50,
          '意志': result.attributes['pow'] ?? 50,
          '教育': result.attributes['edu'] ?? 50,
        });
      }
    }
    final intTotal = (result.attributes['int'] ?? 50) * 2;

    int occSpent = result.skills.values.fold(0, (a, b) => a + b.occ);
    int intSpent = result.skills.values.fold(0, (a, b) => a + b.interest);
    int occRemain = (occTotal - occSpent).clamp(0, 1 << 30);
    int intRemain = (intTotal - intSpent).clamp(0, 1 << 30);
    if (occRemain == 0 && intRemain == 0) return;

    // 单技能当前合计（基础值 + occ + int）
    int currentTotal(String key) {
      final base = SKILL_DEFS.where((s) => s.key == key).firstOrNull?.baseHalf ?? 0;
      final alloc = result.skills[key];
      return base + (alloc?.occ ?? 0) + (alloc?.interest ?? 0);
    }

    final validKeys = SKILL_DEFS.map((s) => s.key).toSet();
    // 候选填充技能：先用 AI 已分配过的技能（保持职业风格），再补通用技能
    final candidates = <String>{};
    candidates.addAll(result.skills.keys
        .where((k) => k != '母语' && validKeys.contains(k) && currentTotal(k) < _skillCap));
    candidates.addAll(_fillerSkills
        .where((k) => validKeys.contains(k) && currentTotal(k) < _skillCap));

    SkillAlloc allocOf(String key) =>
        result.skills[key] ?? SkillAlloc(occ: 0, interest: 0);

    // 先把职业点补完（每次 +5，直到该技能到上限或职业点用完）
    for (final key in candidates) {
      if (occRemain == 0) break;
      while (occRemain > 0 && currentTotal(key) < _skillCap) {
        final a = allocOf(key);
        result.skills[key] = SkillAlloc(occ: a.occ + 5, interest: a.interest);
        occRemain -= 5;
        if (occRemain < 0) {
          // 修正越界（结余 < 5 时）
          final overshoot = -occRemain;
          result.skills[key] = SkillAlloc(occ: a.occ + 5 - overshoot, interest: a.interest);
          occRemain = 0;
        }
      }
    }

    // 再补兴趣点
    for (final key in candidates) {
      if (intRemain == 0) break;
      while (intRemain > 0 && currentTotal(key) < _skillCap) {
        final a = allocOf(key);
        result.skills[key] = SkillAlloc(occ: a.occ, interest: a.interest + 5);
        intRemain -= 5;
        if (intRemain < 0) {
          final overshoot = -intRemain;
          result.skills[key] = SkillAlloc(occ: a.occ, interest: a.interest + 5 - overshoot);
          intRemain = 0;
        }
      }
    }
  }

  Future<Step2Result> generateStep2(String description, Step1Result step1) async {
    final systemPrompt = _buildStep2SystemPrompt();
    final userPrompt = _buildStep2UserPrompt(description, step1);

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await _callApi(systemPrompt, userPrompt);
        return _parseStep2Response(response);
      } catch (e) {
        if (attempt == _maxRetries - 1) rethrow;
      }
    }
    throw Exception('生成失败');
  }

  Future<String> _callApi(String systemPrompt, String userPrompt) async {
    return _callApiWithOptions(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );
  }

  /// 通用对话补全：返回模型生成的文本。
  /// 供 DeepSeek Harness 的资料问答、场景行动等自由文本任务使用。
  Future<String> chat({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) {
    return _callApiWithOptions(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  Future<String> _callApiWithOptions({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final client = _client ?? http.Client();
    try {
      final resp = await client.post(
        Uri.parse(provider.url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': provider.model,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
        }),
      ).timeout(const Duration(seconds: 60));

      if (resp.statusCode != 200) {
        throw Exception('API 请求失败 (${resp.statusCode}): ${resp.body}');
      }

      final data = jsonDecode(resp.body);
      return data['choices'][0]['message']['content'] as String;
    } finally {
      // 注入的 client 由调用方管理，只关闭本方法临时创建的
      if (_client == null) client.close();
    }
  }

  String _extractJson(String response) {
    final codeBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(response);
    if (codeBlock != null) return codeBlock.group(1)!.trim();
    final braceStart = response.indexOf('{');
    final braceEnd = response.lastIndexOf('}');
    if (braceStart >= 0 && braceEnd > braceStart) {
      return response.substring(braceStart, braceEnd + 1);
    }
    throw Exception('AI 未返回有效的 JSON 数据，请重试');
  }

  Step1Result _parseStep1Response(String response) {
    final jsonStr = _extractJson(response);
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    final attrs = data['attributes'] as Map<String, dynamic>;
    final skillsRaw = data['skills'] as Map<String, dynamic>;

    final skills = <String, SkillAlloc>{};
    for (final entry in skillsRaw.entries) {
      final val = entry.value;
      if (val is Map) {
        skills[entry.key] = SkillAlloc(
          occ: (val['occ'] as num? ?? 0).toInt(),
          interest: (val['int'] as num? ?? 0).toInt(),
        );
      } else if (val is num) {
        skills[entry.key] = SkillAlloc(occ: val.toInt(), interest: 0);
      }
    }

    return Step1Result(
      name: (data['name'] ?? '') as String,
      age: (data['age'] ?? '') as String,
      gender: (data['gender'] ?? '') as String,
      residence: (data['residence'] ?? '') as String,
      birthplace: (data['birthplace'] ?? '') as String,
      occupation: (data['occupation'] ?? '') as String,
      occId: (data['occId'] as num?)?.toInt(),
      attributes: {
        'str': (attrs['str'] as num? ?? 50).toInt(),
        'con': (attrs['con'] as num? ?? 50).toInt(),
        'siz': (attrs['siz'] as num? ?? 50).toInt(),
        'dex': (attrs['dex'] as num? ?? 50).toInt(),
        'app': (attrs['app'] as num? ?? 50).toInt(),
        'int': (attrs['int'] as num? ?? 50).toInt(),
        'pow': (attrs['pow'] as num? ?? 50).toInt(),
        'edu': (attrs['edu'] as num? ?? 50).toInt(),
      },
      skills: skills,
    );
  }

  Step2Result _parseStep2Response(String response) {
    final jsonStr = _extractJson(response);
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    final itemsRaw = data['items'] as List<dynamic>? ?? [];
    final items = itemsRaw.map((i) {
      final m = i as Map<String, dynamic>;
      return CharacterItem(
        name: (m['name'] ?? '') as String,
        count: (m['count'] as num? ?? 1).toInt(),
      );
    }).toList();

    // 兜底：如果 AI 仍把"现金"/"钱"等放进 items，剥离出来累加到 cash
    int extractedCash = 0;
    items.removeWhere((it) {
      final name = it.name.trim();
      // 名称完全等于这些词的算作现金条目（避免误删"钱包"、"金币"装备等）
      const cashWords = ['现金', '钱', 'cash', 'Cash', '钞票', '纸币'];
      if (cashWords.contains(name)) {
        extractedCash += it.count;
        return true;
      }
      return false;
    });

    final cashRaw = data['cash'];
    int parsedCash;
    if (cashRaw is num) {
      parsedCash = cashRaw.toInt();
    } else if (cashRaw is String) {
      // 容错：剥掉逗号、货币符号、文字
      final digits = cashRaw.replaceAll(RegExp(r'[^\d-]'), '');
      parsedCash = int.tryParse(digits) ?? 0;
    } else {
      parsedCash = 0;
    }
    parsedCash += extractedCash;

    return Step2Result(
      backstory: (data['backstory'] ?? '') as String,
      appearance: (data['appearance'] ?? '') as String,
      items: items,
      cash: parsedCash,
    );
  }

  bool _validateStep1(Step1Result result, AllocationRule rule, {bool enforceRule = true}) {
    for (final v in result.attributes.values) {
      if (v < AllocationRule.perAttributeMin || v > AllocationRule.perAttributeMax || v % 5 != 0) return false;
    }
    // 购点模式：校验合计严格等于总额（仅当显式指定规则时才检查）
    if (enforceRule && rule.method == AllocationMethod.pointBuy) {
      final sum = result.attributes.values.fold<int>(0, (a, b) => a + b);
      if (sum != rule.pointBuyTotal) return false;
    }
    for (final skillName in result.skills.keys) {
      if (skillName == '母语') continue;
      final def = SKILL_DEFS.where((s) => s.key == skillName).firstOrNull;
      if (def == null) return false;
    }
    final intAttr = result.attributes['int'] ?? 50;
    final interestTotal = intAttr * 2;
    int occSpent = 0;
    int intSpent = 0;
    for (final alloc in result.skills.values) {
      if (alloc.occ < 0 || alloc.interest < 0) return false;
      occSpent += alloc.occ;
      intSpent += alloc.interest;
    }
    if (intSpent > interestTotal) return false;

    // 验证职业点不超支
    if (result.occId != null) {
      final occ = OCCUPATIONS.where((o) => o.id == result.occId).firstOrNull;
      if (occ != null) {
        final attrMap = {
          '力量': result.attributes['str'] ?? 50,
          '体质': result.attributes['con'] ?? 50,
          '体型': result.attributes['siz'] ?? 50,
          '敏捷': result.attributes['dex'] ?? 50,
          '外貌': result.attributes['app'] ?? 50,
          '智力': result.attributes['int'] ?? 50,
          '意志': result.attributes['pow'] ?? 50,
          '教育': result.attributes['edu'] ?? 50,
        };
        final occTotal = calcOccupationPoints(occ.attr, attrMap);
        if (occSpent > occTotal) return false;
      }
    }
    return true;
  }

  String _buildStep1SystemPrompt(AllocationRule rule, Map<String, int>? fixed) {
    final skillList = SKILL_DEFS.map((s) => '${s.key}|${s.baseHalf}').join(', ');
    final occList = OCCUPATIONS.map((o) => '${o.id}|${o.n}|${o.attr}|${o.min}-${o.max}').join('\n');

    final attrRuleSection = fixed != null
        ? '''## 属性已固定（不要修改）
属性值由系统投骰给定，你在 JSON 中可以原样回填，但禁止改动：
str=${fixed['str']} con=${fixed['con']} siz=${fixed['siz']} dex=${fixed['dex']} app=${fixed['app']} int=${fixed['int']} pow=${fixed['pow']} edu=${fixed['edu']}
后续职业匹配、技能分配都必须基于以上数值。'''
        : (rule.method == AllocationMethod.pointBuy
            ? '''## 属性规则（购点 ${rule.pointBuyTotal} 不含运）
- 8 项属性：力量(str)、体质(con)、体型(siz)、敏捷(dex)、外貌(app)、智力(int)、意志(pow)、教育(edu)
- 每项属性必须是 5 的倍数，范围 ${AllocationRule.perAttributeMin}-${AllocationRule.perAttributeMax}
- **8 项属性合计必须严格等于 ${rule.pointBuyTotal}**（请输出前自检）
- 运气不由你生成，由系统单独投骰，不要写入 JSON
- 分配应符合角色描述：例如学者类的 INT/EDU 应偏高，战斗类的 STR/CON 应偏高'''
            : '''## 属性规则
- 8 项属性：力量(str)、体质(con)、体型(siz)、敏捷(dex)、外貌(app)、智力(int)、意志(pow)、教育(edu)
- 每项属性必须是 5 的倍数，范围 ${AllocationRule.perAttributeMin}-${AllocationRule.perAttributeMax}''');

    return '''你是克苏鲁的呼唤（COC）第七版 TRPG 的角色创建助手。你必须严格遵守 COC 7e 规则。
你的回复必须是一个合法的 JSON 对象，不要包含任何其他文字、解释或 markdown 标记。

$attrRuleSection

## 技能规则
- 技能值 = 基础值 + 职业点投入 + 兴趣点投入
- 职业点总额由职业属性公式计算（如"教育×4"表示 EDU×4）
- 兴趣点总额 = 智力(int) × 2
- 职业点总投入不能超过职业点总额
- 兴趣点总投入不能超过兴趣点总额
- 每项技能的职业点投入和兴趣点投入都必须 ≥ 0

## 重要：必须用完技能点
- 你**必须把职业点总额全部分配完**，且**必须把兴趣点总额全部分配完**（occ 总和 = 职业点总额，int 总和 = 兴趣点总额）。
- 不允许剩余职业点或兴趣点，剩余 1 点都不行。
- 分配建议：
  - 职业点应优先重点投入职业相关技能（参考职业列表中的技能集），把核心技能拉到 70-90%。
  - 兴趣点用于补强职业技能或扩展角色背景相关的非职业技能（爱好、副业、经历）。
  - 单项技能合计（基础值+职业点+兴趣点）不要超过 90%。
  - 如果还有零散点数无处可放，分散投入到符合角色背景的杂项技能（如"聆听"、"侦查"、"图书馆使用"、"心理学"、"急救"等通用技能）。
- 输出前请自检：
  1. 把所有 skills 的 occ 字段相加，结果必须**等于**职业点总额。
  2. 把所有 skills 的 int 字段相加，结果必须**等于**兴趣点总额。
  3. 若不相等，调整后再输出。

## 可用技能列表（技能名|基础值）
$skillList

## 职业列表（ID|名称|属性公式|信用范围）
$occList

## 输出格式
严格返回以下 JSON，不要有其他内容：
{
  "name": "角色名",
  "age": "年龄",
  "gender": "性别",
  "residence": "居住地",
  "birthplace": "出生地",
  "occupation": "职业名（必须与职业列表中的名称完全匹配）",
  "occId": 职业ID数字,
  "attributes": {
    "str": 数值, "con": 数值, "siz": 数值, "dex": 数值,
    "app": 数值, "int": 数值, "pow": 数值, "edu": 数值
  },
  "skills": {
    "技能名": {"occ": 职业点投入, "int": 兴趣点投入}
  }
}

skills 中的技能名必须与上方技能列表完全一致。至少分配 10 个技能。
请将"母语"包含在 skills 中，其 occ 和 int 都设为 0。''';
  }

  String _buildStep1UserPrompt(
      String description, String? occupation, AllocationRule rule, Map<String, int>? fixed) {
    final occHint = occupation != null && occupation.isNotEmpty
        ? '指定职业：$occupation，请使用该职业。'
        : '请根据描述选择最合适的职业。';
    final ruleHint = fixed != null
        ? '\n规则：${rule.label}（属性已由系统投骰给定，见 system prompt，禁止修改）'
        : '\n规则：${rule.label}';
    return '请根据以下描述创建一个 COC 7e 角色：\n\n$description\n$ruleHint\n\n$occHint';
  }

  String _buildStep2SystemPrompt() {
    return '''你是克苏鲁的呼唤（COC）第七版 TRPG 的角色创建助手。
你的回复必须是一个合法的 JSON 对象，不要包含任何其他文字或 markdown 标记。

## 输出格式
严格返回以下 JSON：
{
  "backstory": "200-400字的角色背景故事，要求生动具体，包含童年、教育、职业经历、重要事件等",
  "appearance": "100-200字的外貌描写，包含身高、体型、发色、面部特征、穿着风格等",
  "cash": 整数（角色随身现金，单位元/美元/英镑等，依背景时代而定）,
  "items": [
    {"name": "物品名称", "count": 数量}
  ]
}

## 现金规则（cash 字段，整数）
- **现金属于财务，不要写进 items 列表**
- 参考角色的信用评级（Credit Rating）和时代背景估算合理金额：
  - 贫民（CR 0-9）：几元到几十元
  - 普通（CR 10-49）：几十到几百元
  - 富裕（CR 50-89）：几百到几千元
  - 巨富（CR 90+）：上万元甚至更多
- 现代背景（如 2000 年后）金额可适当上调
- 只填数值，不要带单位、千分位逗号、文字

## 物品规则（items 数组）
- 8-15 件物品
- **禁止包含"现金"、"钱"、"钱包里的现金"等条目**（钱包本身作为容器物品可以保留）
- 必须包含：身份证明、日常随身物品
- 根据职业添加专业工具/装备
- 根据背景添加个人特色物品
- count 必须 ≥ 1''';
  }

  String _buildStep2UserPrompt(String description, Step1Result step1) {
    final skillSummary = step1.skills.entries
        .map((e) => '${e.key}(${step1.skills[e.key]!.occ + step1.skills[e.key]!.interest})')
        .join('、');
    return '''请为以下角色生成背景故事、外貌描写和随身物品：

角色名：${step1.name}
职业：${step1.occupation}
年龄：${step1.age}，性别：${step1.gender}，居住地：${step1.residence}
属性：力量${step1.attributes['str']} 体质${step1.attributes['con']} 体型${step1.attributes['siz']} 敏捷${step1.attributes['dex']} 外貌${step1.attributes['app']} 智力${step1.attributes['int']} 意志${step1.attributes['pow']} 教育${step1.attributes['edu']}
已分配技能：$skillSummary

原始描述：$description''';
  }
}
