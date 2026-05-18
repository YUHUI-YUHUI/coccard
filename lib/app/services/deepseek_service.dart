import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/skill.dart';
import '../data/coc_data.dart';
import '../data/character.dart';

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

  Step2Result({
    this.backstory = '',
    this.appearance = '',
    List<CharacterItem>? items,
  }) : items = items ?? [];
}

class DeepSeekService {
  final String apiKey;
  static const _url = 'https://api.deepseek.com/chat/completions';
  static const _maxRetries = 3;

  DeepSeekService({required this.apiKey});

  Future<Step1Result> generateStep1(String description, String? occupation) async {
    final systemPrompt = _buildStep1SystemPrompt();
    final userPrompt = _buildStep1UserPrompt(description, occupation);

    Exception? lastError;
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await _callApi(systemPrompt, userPrompt);
        final result = _parseStep1Response(response);
        final valid = _validateStep1(result);
        if (valid) return result;
        lastError = Exception('生成数据校验失败，正在重试...');
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }
    throw lastError ?? Exception('生成失败');
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
    final resp = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
        'temperature': 0.7,
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
  }

  String _extractJson(String response) {
    final codeBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(response);
    if (codeBlock != null) return codeBlock.group(1)!.trim();
    final braceStart = response.indexOf('{');
    final braceEnd = response.lastIndexOf('}');
    if (braceStart >= 0 && braceEnd > braceStart) {
      return response.substring(braceStart, braceEnd + 1);
    }
    return response;
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
          occ: (val['occ'] ?? 0) as int,
          interest: (val['int'] ?? 0) as int,
        );
      } else if (val is int) {
        // 兼容 AI 直接返回数值的情况
        skills[entry.key] = SkillAlloc(occ: val, interest: 0);
      }
    }

    return Step1Result(
      name: (data['name'] ?? '') as String,
      age: (data['age'] ?? '') as String,
      gender: (data['gender'] ?? '') as String,
      residence: (data['residence'] ?? '') as String,
      birthplace: (data['birthplace'] ?? '') as String,
      occupation: (data['occupation'] ?? '') as String,
      occId: data['occId'] as int?,
      attributes: {
        'str': (attrs['str'] ?? 50) as int,
        'con': (attrs['con'] ?? 50) as int,
        'siz': (attrs['siz'] ?? 50) as int,
        'dex': (attrs['dex'] ?? 50) as int,
        'app': (attrs['app'] ?? 50) as int,
        'int': (attrs['int'] ?? 50) as int,
        'pow': (attrs['pow'] ?? 50) as int,
        'edu': (attrs['edu'] ?? 50) as int,
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
        count: (m['count'] ?? 1) as int,
      );
    }).toList();

    return Step2Result(
      backstory: (data['backstory'] ?? '') as String,
      appearance: (data['appearance'] ?? '') as String,
      items: items,
    );
  }

  bool _validateStep1(Step1Result result) {
    // 校验属性值
    for (final v in result.attributes.values) {
      if (v < 40 || v > 90 || v % 5 != 0) return false;
    }

    // 校验技能名是否在 SKILL_DEFS 中
    for (final skillName in result.skills.keys) {
      if (skillName == '母语') continue; // 母语特殊处理
      final def = SKILL_DEFS.where((s) => s.key == skillName).firstOrNull;
      if (def == null) return false;
    }

    // 校验点数不超限
    final intAttr = result.attributes['int'] ?? 50;
    final interestTotal = intAttr * 2;

    int intSpent = 0;
    for (final alloc in result.skills.values) {
      if (alloc.occ < 0 || alloc.interest < 0) return false;
      intSpent += alloc.interest;
    }

    // 兴趣点不能超限（职业点需要职业公式计算，这里只校验兴趣点）
    if (intSpent > interestTotal) return false;

    return true;
  }

  String _buildStep1SystemPrompt() {
    // 构建技能列表字符串
    final skillList = SKILL_DEFS.map((s) => '${s.key}|${s.baseHalf}').join(', ');

    // 构建职业列表字符串
    final occList = OCCUPATIONS.map((o) => '${o.id}|${o.n}|${o.attr}|${o.min}-${o.max}').join('\n');

    return '''你是克苏鲁的呼唤（COC）第七版 TRPG 的角色创建助手。你必须严格遵守 COC 7e 规则。
你的回复必须是一个合法的 JSON 对象，不要包含任何其他文字、解释或 markdown 标记。

## 属性规则
- 8 项属性：力量(str)、体质(con)、体型(siz)、敏捷(dex)、外貌(app)、智力(int)、意志(pow)、教育(edu)
- 每项属性值必须是 5 的倍数，范围 40-90
- 标准生成方式为 3D6×5（3个六面骰之和乘以5）

## 技能规则
- 技能值 = 基础值 + 职业点投入 + 兴趣点投入
- 职业点总额由职业属性公式计算（如"教育×4"表示 EDU×4）
- 兴趣点总额 = 智力(int) × 2
- 职业点总投入不能超过职业点总额
- 兴趣点总投入不能超过兴趣点总额
- 每项技能的职业点投入和兴趣点投入都必须 ≥ 0

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

  String _buildStep1UserPrompt(String description, String? occupation) {
    final occHint = occupation != null && occupation.isNotEmpty
        ? '指定职业：$occupation，请使用该职业。'
        : '请根据描述选择最合适的职业。';
    return '请根据以下描述创建一个 COC 7e 角色：\n\n$description\n\n$occHint';
  }

  String _buildStep2SystemPrompt() {
    return '''你是克苏鲁的呼唤（COC）第七版 TRPG 的角色创建助手。
你的回复必须是一个合法的 JSON 对象，不要包含任何其他文字或 markdown 标记。

## 输出格式
严格返回以下 JSON：
{
  "backstory": "200-400字的角色背景故事，要求生动具体，包含童年、教育、职业经历、重要事件等",
  "appearance": "100-200字的外貌描写，包含身高、体型、发色、面部特征、穿着风格等",
  "items": [
    {"name": "物品名称", "count": 数量}
  ]
}

## 物品规则
- 8-15 件物品
- 必须包含：身份证明、钱包/现金、日常随身物品
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
