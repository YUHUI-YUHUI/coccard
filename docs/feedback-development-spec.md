# COC7 反馈项开发文档

版本：v0.1  
整理日期：2026-06-05  
适用项目：coccard Flutter 应用  
反馈来源：截图反馈

## 1. 背景与目标

本轮反馈集中在技能页展示、D100 检定规则、疯狂发作结果展示、骰点功能边界，以及技能成长记录五个方向。目标是在不破坏现有角色卡数据结构和页面入口的前提下，将这些反馈整理成可以直接进入开发排期的需求文档。

一期目标：

- 修复技能筛选标签在小屏或高字号场景下显示不完整的问题。
- 支持 D100 检定的村规配置，例如大成功为 1-5，大失败为 96-100。
- 临时疯狂结果同时显示症状和持续轮数。
- 明确骰点功能一期为本地骰点与本地记录，不默认等同联机。
- 记录技能检定成功/失败次数，并支持成长标记与幕间成长流程。

非一期目标：

- 实时联机房间、多人同步骰点、公证骰点记录。
- 完整战斗回合系统。
- 完整 SAN 损失表达式解析和不定疯狂全流程。

## 2. 反馈拆解

| 序号 | 反馈原文 | 产品目标 | 优先级 | 影响模块 |
| --- | --- | --- | --- | --- |
| 1 | 显示不完全 | 技能页顶部筛选标签在窄屏完整可读、可点击、选中态明确 | P0 | `SkillPage`、主题样式 |
| 2 | 村规转换，例如大成功 1-5，大失败 96-100 | D100 结果判定从硬编码改为可配置规则 | P0 | 检定规则模型、设置页、技能检定 |
| 3 | 临时疯狂同时显示症状和轮数 | 随机疯狂弹窗一次展示症状条目和持续时间 | P1 | `ReferencePage`、理智/疯狂记录 |
| 4 | 骰点功能 -> 是否意味着联机 | 明确功能边界，避免用户误解本地投骰就是联机 | P1 | `DiceRollerWidget`、文案、后续联机方案 |
| 5 | 增加记录检定成功/失败的对应技能和次数，方便成长 | 技能检定后沉淀统计和成长标记 | P0 | `Character`、`CharacterManager`、`SkillPage` |

## 3. 当前实现概览

### 3.1 技能页筛选标签

当前 `lib/app/pages/skill_page.dart` 使用 `AppBar.bottom` 内的 `TabBar`，四个标签为：

- 本职
- 已加点
- 推荐未加
- 全部

该 `TabBar` 已设置 `isScrollable: true` 和 `tabAlignment: TabAlignment.start`，避免技能页在窄屏、高字号、部分系统字体下截断或挤压。对应回归测试见 `test/skill_page_test.dart`。

### 3.2 D100 技能检定

当前 `_evaluateSkillCheck` 已支持：

- 大成功：`roll == 1`
- 极难成功：小于等于五分之一值
- 困难成功：小于等于半值
- 普通成功：小于等于目标值
- 大失败：目标值低于 50 时 `96-100`，目标值 50 或以上时 `100`
- 花费幸运补成普通成功

问题：

- 大成功和大失败规则硬编码在页面内。
- 没有设置入口，无法切换到常见村规。
- 检定逻辑与 UI 耦合，不利于单元测试和其他页面复用。

### 3.3 临时疯狂

当前 `ReferencePage` 已有即时症状、长期症状、恐惧症、躁狂症参考表，也有随机触发按钮。即时症状区域写明“1D10轮后消失”，但弹窗只显示症状编号和文本，没有投出并展示具体轮数。

### 3.4 骰点功能

当前 `DiceRollerWidget` 是本地组件，只保存当前页面状态中的 D100 和 3D6 结果，不写入角色数据，不生成历史记录，也没有网络、房间、用户身份或同步机制。

因此一期应将骰点功能定义为：

- 本地投骰工具。
- 可选择写入本地检定日志。
- 不代表联机，不承诺远端同步。

### 3.5 技能检定记录与成长

当前角色数据 `Character` 包含 `skills`，但没有技能检定日志、成功/失败次数、成长标记或成长历史。技能检定在弹窗关闭后不保留结果。后续成长只能靠玩家手动记忆。

## 4. 需求规格

### 4.1 修复筛选标签显示不完全

实现状态：已完成。`SkillPage` 顶部筛选标签已改为可滚动 `TabBar`，并补充 360px 宽度、1.3 倍系统字号的 widget 回归测试。

用户故事：

作为玩家，我在手机屏幕上进入技能页时，应能清楚看到并切换“本职、已加点、推荐未加、全部”四个筛选入口。

开发建议：

- 将 `SkillPage` 的 `TabBar` 改为 `isScrollable: true`。
- 或改成页面内 `SingleChildScrollView + SegmentedButton/ChoiceChip`，避免 AppBar 内空间压缩。
- 保留当前四个筛选含义，不改业务逻辑。
- 若继续使用 `TabBar`，参考 `ReferencePage` 的滚动 TabBar 实现。

验收标准：

- 在 360px、390px、430px 宽度下四个标签不截断。
- 系统字体放大到 1.3 倍时，标签仍可横向滚动查看。
- 当前选中标签的颜色/指示器清晰。
- 切换标签后列表筛选结果与当前实现一致。

### 4.2 D100 村规转换

用户故事：

作为守秘人，我希望在设置中选择本桌 D100 规则，例如“大成功 1-5、大失败 96-100”，技能检定时按该规则展示结果。

默认规则：

- 大成功：1。
- 大失败：目标值低于 50 时为 96-100，目标值 50 或以上时为 100。

村规配置：

- 大成功阈值：默认 1，可配置为 1-5。
- 大失败阈值：默认按 COC7 原规则，可配置为固定 96-100。
- 是否允许花费幸运补正：沿用现有逻辑，后续可独立配置。

建议新增模型：

```dart
enum CriticalRuleMode {
  oneOnly,
  fixedRange,
}

enum FumbleRuleMode {
  coc7,
  fixedRange,
}

class CheckRuleProfile {
  final String id;
  final String name;
  final CriticalRuleMode criticalMode;
  final int criticalMax;
  final FumbleRuleMode fumbleMode;
  final int fumbleMin;
  final bool allowSpendLuck;
}
```

建议新增服务：

```dart
class D100CheckEvaluator {
  SkillCheckResult evaluate({
    required int target,
    required int roll,
    required CheckRuleProfile rule,
  });
}
```

判定顺序：

1. 校验配置，避免大成功范围与大失败范围重叠。
2. 大成功优先于普通成功等级。
3. 大失败优先于普通失败。
4. 其余结果按极难、困难、普通、失败判断。

设置页入口：

- 新增“检定规则”区域。
- 提供预设：
  - COC7 默认。
  - 常用村规：大成功 1-5，大失败 96-100。
  - 自定义。
- 保存到 `AppPreferences`，例如 key 为 `check_rule_profile`。

验收标准：

- 默认规则下当前行为不变。
- 选择村规后，掷出 1-5 显示大成功。
- 选择村规后，掷出 96-100 显示大失败。
- 规则切换后，技能页一键检定、骰点页 D100 检定使用同一套判定。
- 增加单元测试覆盖目标值 40、50、80 下的边界结果。

### 4.3 临时疯狂同时显示症状和轮数

用户故事：

作为玩家，当触发临时疯狂时，我希望一次看到随机症状和持续轮数，不需要再额外投一次时间。

开发建议：

- 即时症状按钮点击后，同时投：
  - 症状：1D10，对应 `INSANITY_TMP`。
  - 持续轮数：1D10 轮。
- 长期症状按钮点击后，同时投：
  - 症状：1D10，对应 `INSANITY_LONG`。
  - 持续时间：1D10 小时。
- 弹窗标题示例：`即时症状 #6，持续 7 轮`。
- 弹窗正文显示症状文本、骰点详情和是否写入记录的按钮。

建议新增记录结构：

```dart
class InsanityEpisode {
  final String id;
  final String type; // temporary 或 indefinite
  final int symptomRoll;
  final String symptomText;
  final int durationRoll;
  final String durationUnit; // 轮 或 小时
  final int? sanityLoss;
  final DateTime createdAt;
}
```

一期可以只在参考表弹窗中展示症状和轮数。二期再接入 SAN 损失、INT 检定和角色记录。

验收标准：

- 点击“即时症状”后弹窗同时出现症状编号、症状文本、持续 N 轮。
- 点击“长期症状”后弹窗同时出现症状编号、症状文本、持续 N 小时。
- N 的范围为 1-10。
- 弹窗文案不再只写泛化的“1D10轮后消失”。

### 4.4 骰点功能边界

用户故事：

作为玩家，我需要明确“骰点功能”是本地工具还是联机同步，以便知道结果是否会同步给其他玩家或守秘人。

一期定义：

- 骰点功能是本地工具。
- 本地结果可以写入当前角色的检定记录。
- UI 文案避免使用“联机”“同步”“公开房间”等词。
- 若需要可信骰点，由玩家自行展示屏幕或后续进入联机功能。

二期联机候选需求：

- 创建或加入房间。
- 房间内角色身份和玩家昵称。
- 投骰结果实时同步到房间日志。
- 日志包含投骰人、技能、目标值、骰面、成功等级、时间。
- 支持断线重连和历史记录拉取。

建议一期改动：

- 将首页骰点按钮文案保持为“投骰子”或“本地投骰”。
- `DiceRollerWidget` 中增加结果列表，最近 N 条本地投骰可见。
- 技能页检定默认写入角色本地记录。
- 暂不新增网络依赖。

验收标准：

- 用户不会在界面上看到暗示联机的文案。
- 本地 D100 投骰可以选择是否记录到当前角色。
- 没有角色时仍可作为纯本地骰点工具使用。

### 4.5 技能检定记录与成长

用户故事：

作为玩家，我希望应用记录每个技能检定成功/失败的次数，并在技能成功后提示成长标记，幕间可以统一处理成长。

建议新增数据结构：

```dart
class SkillCheckRecord {
  final String id;
  final String skillName;
  final int skillValue;
  final int roll;
  final String level;
  final bool success;
  final String ruleProfileId;
  final DateTime createdAt;
}

class SkillGrowthState {
  final String skillName;
  int successCount;
  int failureCount;
  bool growthMarked;
  DateTime? lastCheckedAt;
  DateTime? lastGrowthAt;
}
```

建议在 `Character` 中新增字段：

```dart
List<SkillCheckRecord> skillCheckRecords;
Map<String, SkillGrowthState> skillGrowth;
```

也可以只保存 `skillCheckRecords`，统计值运行时计算。但考虑移动端列表展示性能，一期建议保存聚合统计 `skillGrowth`，日志保留最近 100-300 条。

记录触发点：

- 技能页一键检定后自动记录。
- 本地骰点 D100 若选择了技能，也记录。
- 花费幸运补正后，记录中保留原始结果，并增加 `finalSuccess` 字段或补正事件。

成长逻辑：

- 默认只有技能检定成功时自动设置 `growthMarked = true`。
- 玩家可以手动取消或补打成长标记。
- 幕间成长检定时，对已标记技能掷 D100。
- 成长检定需要掷出大于当前技能值才成长。
- 成长成功后增加 1D10，清除成长标记，写入成长历史。

技能页展示：

- 技能条目中增加小型统计区域：
  - `成功 3`
  - `失败 1`
  - `成长待检`
- 列表顶部或更多菜单增加“成长记录/幕间成长”入口。
- 成长待检技能可以被筛选或排序到前面。

验收标准：

- 完成一次技能检定后，当前技能的成功或失败次数 +1。
- 成功检定后，该技能显示成长标记。
- 失败检定不会默认添加成长标记，但会累计失败次数。
- 角色导出 JSON 包含检定记录和成长状态。
- 旧角色数据导入后字段为空列表/空 Map，不崩溃。

## 5. 开发任务拆分

### P0：本轮优先

1. 修复 `SkillPage` 顶部标签显示。
2. 抽出 D100 检定判定服务，并补单元测试。
3. 在设置页新增检定规则配置。
4. 在 `Character` 中增加技能检定记录和成长状态字段。
5. 技能页一键检定写入成功/失败统计和成长标记。

### P1：紧随其后

1. 临时疯狂弹窗同时显示症状和持续轮数。
2. 长期症状弹窗同时显示症状和持续小时数。
3. 技能页展示成功/失败次数和成长待检标记。
4. 增加本地骰点历史，不使用联机措辞。

### P2：可后置

1. 幕间成长批量处理页面。
2. SAN 损失表达式解析和临时疯狂自动触发流程。
3. 检定日志筛选、清理、导出。
4. 联机骰点房间设计。

## 6. 数据迁移与兼容

角色 JSON 当前通过 `Character.toJson` 和 `Character.fromJson` 存入 `SharedPreferences`。新增字段必须满足：

- 旧 JSON 中缺字段时使用默认值。
- 导入旧备份不报错。
- 新字段导出后仍可被当前版本读取。
- 日志字段数量可控，避免 SharedPreferences 过大。

建议默认值：

```dart
skillCheckRecords: [],
skillGrowth: {},
insanityEpisodes: [],
```

建议日志保留策略：

- 默认保留最近 200 条技能检定。
- 可在设置页提供“清空检定记录”。
- 聚合统计不随日志裁剪而丢失，除非用户明确重置成长统计。

## 7. 测试计划

单元测试：

- 默认 COC7 规则：
  - 目标 40，96 为大失败。
  - 目标 50，96 为失败，100 为大失败。
  - 目标 80，1 为大成功。
- 村规：
  - 1-5 为大成功。
  - 96-100 为大失败。
  - 6 在目标足够高时按普通成功等级计算。
- 成长统计：
  - 成功次数、失败次数正确累加。
  - 成功后 growthMarked 为 true。
  - 旧 JSON 缺字段时正常反序列化。

Widget 测试：

- 技能页四个筛选标签在窄屏下可滚动或完整显示。
- 技能检定后列表显示统计更新。
- 临时疯狂弹窗显示症状和轮数。

手工验收：

- Android 小屏机型。
- iOS 小屏机型。
- 深色模式。
- 中文系统字体放大。
- 角色导出/导入。

## 8. 待确认问题

1. 村规是否只需要“大成功 1-5、大失败 96-100”这一组预设，还是需要完全自定义阈值？
2. 成长标记是否严格按 COC7 的“成功后标记”，还是本桌希望失败也可以进入成长候选？
3. 检定记录是否需要展示完整历史列表，还是只展示每个技能的成功/失败次数？
4. 骰点联机是否有明确需求？若有，需要确定是否走账号体系、房间码、局域网或第三方服务。

## 9. 建议落地顺序

推荐先实现 P0。原因是 P0 会打通核心数据结构和规则判定服务，后续临时疯狂、骰点记录、幕间成长都可以复用同一套检定结果模型。

第一轮开发完成后，应至少交付：

- 技能页标签显示修复。
- 可切换的 D100 默认规则/村规。
- 技能检定自动记录成功失败次数。
- 成功技能自动出现成长标记。
- 旧角色数据兼容。

## 10. 后续功能提案

当 5 节任务清单全部完成后，由每日 cron 自动分析代码结构并产出可落地的开发文档。每份提案落到 `docs/feature-proposals/YYYY-MM-DD-功能简述.md`，并在此节维护索引。

### 10.1 技能检定日志筛选、清理、导出（P2#3 细化）

- **提出日期**：2026-06-12
- **对应任务**：P2#3「检定日志筛选、清理、导出」
- **完整文档**：`docs/feature-proposals/2026-06-12-技能检定日志筛选清理导出.md`
- **范围**：技能检定日志（`SkillCheckRecord`）的筛选 / 清理 / 导出 CSV / 导出 JSON；不影响本地骰点历史（`DiceRollRecord`）。
- **核心数据**：`SkillCheckLogFilter`（UI 层临时状态，不持久化）、CSV 列固定 9 字段、JSON 顶层带 `schema: coccard.skill_check_log.v1`。
- **核心控制器**：`SkillCheckLogController`（`ChangeNotifier`），复用 `CharacterManager` 写入路径，不新增 SharedPreferences key。
- **UI 入口**：`SkillPage` AppBar 新增 `Icons.history` 按钮，跳转 `/skill_check_log`；页面内含筛选条 + 三 action（筛选 / 清理 / 导出）。
- **任务拆分**：6 步，每步独立 commit；顺序为 controller → page → SkillPage 入口 → main 路由 → 2 个测试文件。
- **测试矩阵**：10 条 controller 单元测试 + 3 条 widget 测试；不依赖 `intl` 包；CSV 使用 `\uFEFF` BOM 兼容 Excel。
- **兼容性**：不修改 `Character` / `SkillCheckRecord` / `SkillGrowthState` 数据结构；旧 JSON 已由 P0#4 处理默认值。
- **风险**：CSV 转义按 RFC 4180；清理确认弹窗前置导出菜单，避免误删无法回滚。

### 10.2 联机骰点房间设计（P2#4 细化）

- **提出日期**：2026-06-17
- **对应任务**：P2#4「联机骰点房间设计」
- **完整文档**：`docs/feature-proposals/2026-06-17-联机骰点房间设计.md`
- **范围**：联机骰点房间（创建/加入房间、服务端骰面生成、实时同步、房间日志、投骰动画）；不影响本地骰点功能（`DiceRollerWidget`、`DiceHistoryController`）。
- **核心数据**：`DiceRoom`（房间模型）、`DiceRoomMember`（成员模型）、`DiceMessage`（骰点消息模型）、`DiceUserIdentity`（用户身份，本地持久化）。
- **架构方案**：推荐 Firebase Cloud Firestore + Cloud Functions（骰面由服务端生成并签名，客户端通过 `onSnapshot` 实时接收）；降级方案为 WebSocket 自建服务端。
- **安全机制**：`dice_messages` 集合的 Firestore Security Rules 禁止客户端写入，骰面由 Cloud Function 使用 `crypto.randomBytes` 生成并 HMAC-SHA256 签名。
- **任务拆分**：11 步，每步独立 commit；顺序为 Firebase 初始化 → 用户身份 → 数据模型 → 服务层 → Cloud Functions → 房间列表页 → 房间内页 → 投骰动画 → 入口整合 → 断线重连 → 测试。
- **测试计划**：6 条模型单元测试 + 7 条集成测试（Firebase Emulator）+ 4 条 Widget 测试 + 6 项手工验收。
- **兼容性**：不修改 `DiceRollRecord`、`DiceHistoryController`、`DiceRollerWidget`；联机和本地骰点并存，共享 `D100CheckEvaluator` 检定逻辑。
- **风险**：Firebase 在中国大陆不可用（需降级方案）；Cloud Functions 冷启动延迟（Blaze 计划缓解）；匿名用户身份不可靠（设备 UUID 解决）。

### 10.3 战斗追踪器（Combat Tracker）

- **提出日期**：2026-06-18
- **完整文档**：`docs/feature-proposals/2026-06-18-战斗追踪器.md`
- **范围**：战斗实例管理（创建/结束）、参战者列表（PC + 临时 NPC）、行动顺序（DEX 排序）、HP 实时追踪（受伤/昏迷/濒死/死亡自动标记）、特殊状态标签、轮次计数、战斗摘要、本地持久化。
- **核心数据**：`CombatEncounter`（战斗实例）、`Combatant`（参战者）、`CombatantType` / `CombatantStatus` 枚举。
- **核心控制器**：`CombatController`（`ChangeNotifier`），独立 SharedPreferences key（`combat_encorders`），不修改 `Character` 现有字段。
- **UI 入口**：`AppDrawerWidget` 新增战斗入口 → `/combat`（战斗列表页）→ 点击进入 `/combat_detail`（战斗主页面）。
- **任务拆分**：8 步，顺序为数据模型 → controller → 列表页 → 主页面 → 添加参战者弹窗 → 战斗摘要 → 路由入口 → widget 测试。
- **测试矩阵**：7 条模型单元测试 + 6 条 controller 单元测试 + 3 条 widget 测试。
- **兼容性**：不修改 `Character` / `SkillCheckRecord` / 其他现有数据结构；旧 JSON 无影响。
- **风险**：长战斗数据量可能导致 SharedPreferences 写入变慢（限制历史 20 场缓解）；HP 高频修改需 debounce 保存。
