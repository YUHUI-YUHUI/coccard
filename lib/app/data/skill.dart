enum SkillCategory { combat, shooting, social, academic, stealth, athletic, perception, knowledge, craft, other }

class SkillDef {
  final String key;
  final String name;
  final SkillCategory category;
  final int baseHalf;
  final int baseFifth;
  const SkillDef({required this.key, required this.name, required this.category, required this.baseHalf, required this.baseFifth});
}

const Map<String, SkillCategory> SKILL_CATEGORIES = {
  '格斗': SkillCategory.combat, '射击': SkillCategory.shooting, '社交': SkillCategory.social,
  '学术': SkillCategory.academic, '隐秘': SkillCategory.stealth, '运动': SkillCategory.athletic,
  '感知': SkillCategory.perception, '知识': SkillCategory.knowledge, '技艺': SkillCategory.craft, '其他': SkillCategory.other,
};

const List<SkillDef> SKILL_DEFS = [
  SkillDef(key:'格斗（斗殴）', name:'格斗（斗殴）', category:SkillCategory.combat, baseHalf:25, baseFifth:10),
  SkillDef(key:'格斗（刃）', name:'格斗（刃）', category:SkillCategory.combat, baseHalf:25, baseFifth:10),
  SkillDef(key:'格斗（棍）', name:'格斗（棍）', category:SkillCategory.combat, baseHalf:25, baseFifth:10),
  SkillDef(key:'格斗（矛）', name:'格斗（矛）', category:SkillCategory.combat, baseHalf:25, baseFifth:10),
  SkillDef(key:'格斗（斧）', name:'格斗（斧）', category:SkillCategory.combat, baseHalf:20, baseFifth:8),
  SkillDef(key:'格斗（绞）', name:'格斗（绞）', category:SkillCategory.combat, baseHalf:25, baseFifth:10),
  SkillDef(key:'格斗（鞭）', name:'格斗（鞭）', category:SkillCategory.combat, baseHalf:20, baseFifth:8),
  SkillDef(key:'射击（火器）', name:'射击（火器）', category:SkillCategory.shooting, baseHalf:20, baseFifth:8),
  SkillDef(key:'射击（霰弹枪）', name:'射击（霰弹枪）', category:SkillCategory.shooting, baseHalf:25, baseFifth:10),
  SkillDef(key:'射击（步枪）', name:'射击（步枪）', category:SkillCategory.shooting, baseHalf:25, baseFifth:10),
  SkillDef(key:'射击（冲锋枪）', name:'射击（冲锋枪）', category:SkillCategory.shooting, baseHalf:15, baseFifth:6),
  SkillDef(key:'射击（弓）', name:'射击（弓）', category:SkillCategory.shooting, baseHalf:15, baseFifth:6),
  SkillDef(key:'射击（弩）', name:'射击（弩）', category:SkillCategory.shooting, baseHalf:20, baseFifth:8),
  SkillDef(key:'射击（机枪）', name:'射击（机枪）', category:SkillCategory.shooting, baseHalf:15, baseFifth:6),
  SkillDef(key:'射击（其他）', name:'射击（其他）', category:SkillCategory.shooting, baseHalf:20, baseFifth:8),
  SkillDef(key:'魅惑', name:'魅惑', category:SkillCategory.social, baseHalf:15, baseFifth:6),
  SkillDef(key:'话术', name:'话术', category:SkillCategory.social, baseHalf:10, baseFifth:4),
  SkillDef(key:'恐吓', name:'恐吓', category:SkillCategory.social, baseHalf:15, baseFifth:6),
  SkillDef(key:'说服', name:'说服', category:SkillCategory.social, baseHalf:10, baseFifth:4),
  SkillDef(key:'会计', name:'会计', category:SkillCategory.academic, baseHalf:10, baseFifth:4),
  SkillDef(key:'人类学', name:'人类学', category:SkillCategory.academic, baseHalf:1, baseFifth:1),
  SkillDef(key:'估价', name:'估价', category:SkillCategory.academic, baseHalf:5, baseFifth:2),
  SkillDef(key:'考古学', name:'考古学', category:SkillCategory.academic, baseHalf:1, baseFifth:1),
  SkillDef(key:'艺术/手艺', name:'艺术/手艺', category:SkillCategory.academic, baseHalf:5, baseFifth:2),
  SkillDef(key:'技艺（表演）', name:'技艺（表演）', category:SkillCategory.academic, baseHalf:5, baseFifth:2),
  SkillDef(key:'技艺（摄影）', name:'技艺（摄影）', category:SkillCategory.academic, baseHalf:5, baseFifth:2),
  SkillDef(key:'技艺（绘画）', name:'技艺（绘画）', category:SkillCategory.academic, baseHalf:5, baseFifth:2),
  SkillDef(key:'技艺（音乐）', name:'技艺（音乐）', category:SkillCategory.academic, baseHalf:5, baseFifth:2),
  SkillDef(key:'技艺（烹饪）', name:'技艺（烹饪）', category:SkillCategory.academic, baseHalf:5, baseFifth:2),
  SkillDef(key:'技艺（其他）', name:'技艺（其他）', category:SkillCategory.academic, baseHalf:5, baseFifth:2),
  SkillDef(key:'法律', name:'法律', category:SkillCategory.academic, baseHalf:5, baseFifth:2),
  SkillDef(key:'历史', name:'历史', category:SkillCategory.academic, baseHalf:20, baseFifth:8),
  SkillDef(key:'图书馆', name:'图书馆', category:SkillCategory.academic, baseHalf:20, baseFifth:8),
  SkillDef(key:'母语', name:'母语', category:SkillCategory.academic, baseHalf:0, baseFifth:0),
  SkillDef(key:'外语', name:'外语', category:SkillCategory.academic, baseHalf:1, baseFifth:1),
  SkillDef(key:'医学', name:'医学', category:SkillCategory.academic, baseHalf:1, baseFifth:1),
  SkillDef(key:'自然', name:'自然', category:SkillCategory.academic, baseHalf:10, baseFifth:4),
  SkillDef(key:'神秘学', name:'神秘学', category:SkillCategory.academic, baseHalf:5, baseFifth:2),
  SkillDef(key:'心理学', name:'心理学', category:SkillCategory.academic, baseHalf:10, baseFifth:4),
  SkillDef(key:'科学', name:'科学', category:SkillCategory.academic, baseHalf:1, baseFifth:1),
  SkillDef(key:'精神分析', name:'精神分析', category:SkillCategory.academic, baseHalf:1, baseFifth:1),
  SkillDef(key:'乔装', name:'乔装', category:SkillCategory.stealth, baseHalf:5, baseFifth:2),
  SkillDef(key:'锁匠', name:'锁匠', category:SkillCategory.stealth, baseHalf:1, baseFifth:1),
  SkillDef(key:'妙手', name:'妙手', category:SkillCategory.stealth, baseHalf:10, baseFifth:4),
  SkillDef(key:'潜行', name:'潜行', category:SkillCategory.stealth, baseHalf:20, baseFifth:8),
  SkillDef(key:'侦查', name:'侦查', category:SkillCategory.stealth, baseHalf:25, baseFifth:10),
  SkillDef(key:'攀爬', name:'攀爬', category:SkillCategory.athletic, baseHalf:20, baseFifth:8),
  SkillDef(key:'跳跃', name:'跳跃', category:SkillCategory.athletic, baseHalf:20, baseFifth:8),
  SkillDef(key:'游泳', name:'游泳', category:SkillCategory.athletic, baseHalf:20, baseFifth:8),
  SkillDef(key:'驾驶（汽车）', name:'驾驶（汽车）', category:SkillCategory.athletic, baseHalf:20, baseFifth:8),
  SkillDef(key:'驾驶（船）', name:'驾驶（船）', category:SkillCategory.athletic, baseHalf:20, baseFifth:8),
  SkillDef(key:'驾驶（飞机）', name:'驾驶（飞机）', category:SkillCategory.athletic, baseHalf:1, baseFifth:1),
  SkillDef(key:'骑术', name:'骑术', category:SkillCategory.athletic, baseHalf:5, baseFifth:2),
  SkillDef(key:'投掷', name:'投掷', category:SkillCategory.athletic, baseHalf:20, baseFifth:8),
  SkillDef(key:'聆听', name:'聆听', category:SkillCategory.perception, baseHalf:20, baseFifth:8),
  SkillDef(key:'侦察', name:'侦察', category:SkillCategory.perception, baseHalf:10, baseFifth:4),
  SkillDef(key:'追踪', name:'追踪', category:SkillCategory.perception, baseHalf:10, baseFifth:4),
  SkillDef(key:'计算机', name:'计算机', category:SkillCategory.knowledge, baseHalf:1, baseFifth:1),
  SkillDef(key:'电子学', name:'电子学', category:SkillCategory.knowledge, baseHalf:1, baseFifth:1),
  SkillDef(key:'电气维修', name:'电气维修', category:SkillCategory.knowledge, baseHalf:10, baseFifth:4),
  SkillDef(key:'机械维修', name:'机械维修', category:SkillCategory.knowledge, baseHalf:10, baseFifth:4),
  SkillDef(key:'生存', name:'生存', category:SkillCategory.other, baseHalf:10, baseFifth:4),
  SkillDef(key:'导航', name:'导航', category:SkillCategory.other, baseHalf:10, baseFifth:4),
  SkillDef(key:'潜水', name:'潜水', category:SkillCategory.other, baseHalf:1, baseFifth:1),
  SkillDef(key:'急救', name:'急救', category:SkillCategory.other, baseHalf:10, baseFifth:4),
  SkillDef(key:'克苏鲁神话', name:'克苏鲁神话', category:SkillCategory.other, baseHalf:0, baseFifth:0),
  SkillDef(key:'闪避', name:'闪避', category:SkillCategory.athletic, baseHalf:20, baseFifth:8),
];

SkillDef? getSkillDef(String key) {
  try { return SKILL_DEFS.firstWhere((s) => s.key == key); } catch (_) { return null; }
}
