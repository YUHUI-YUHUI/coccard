# COC Card 项目任务文档

## 项目简介
- **项目名称**: COC Card (coccard)
- **项目类型**: Flutter 移动应用（Android/iOS）+ Web
- **功能**: 克苏鲁的呼唤 第七版 角色卡管理工具，支持角色属性管理、技能点分配、武器管理、PDF导出等功能
- **主要技术**: Flutter, Dart, PDF生成（pdf + printing包）
- **代码位置**: `lib/` 目录下
- **资源文件**: `assets/` 目录下包含背景图（coc卡_01.png/coc卡_02.png为新版模板）、字体等
- **数据文件**: `lib/app/data/coc_data.dart` 包含职业数据（OCCUPATIONS）

## 任务列表

- COC7 规则缺口修复（按优先级）
  1. 修正衍生属性公式
     - 起始 SAN 应等于 POW，最大 SAN 通常为 `99 - 克苏鲁神话`，不应写成 `99 - POW`。
     - HP、MP 保留规则校验：HP = `(CON + SIZ) / 10` 向下取整；MP = `POW / 5` 向下取整。
     - 重新实现 MOV：按 COC7 的 STR/DEX 与 SIZ 比较规则计算，并考虑年龄修正。
     - 重新实现 Damage Bonus / Build：按 STR + SIZ 查表，不应使用当前线性区间。
     - 修正属性变更时覆盖当前 HP/MP/SAN 的逻辑，避免编辑属性直接把受伤/损失状态重置。
  2. 修正并补全技能基础值与技能表
     - 修正基础值：会计 05、话术 05、急救 30、历史 05、闪避 = DEX/2 等。
     - 补全标准技能：信用评级、操作重型机械、射击（手枪）、射击（步枪/霰弹枪）等。
     - 统一技能名称，处理“侦查/侦察”“驾驶（汽车）/汽车驾驶”“图书馆/图书馆使用”等别名。
     - 支持专业化技能条目：艺术/手艺、科学、语言、格斗、射击、驾驶、生存等自定义分支。
  3. 完善 D100 检定系统
     - 显示普通/困难/极难成功等级。
     - 修正大成功/大失败规则，按技能值区间处理 96-100 与 100。
     - 支持奖励骰、惩罚骰、Push Roll、Luck Roll。
     - 支持对抗检定与比较成功等级。
  4. 实现 SAN 与疯狂流程
     - 支持 `0/1D6`、`1/1D10` 等 SAN 损失表达式。
     - 处理一次损失 5 点触发临时疯狂、INT 检定、即时症状/总结症状。
     - 记录临时疯狂、不定疯狂、恐惧症、躁狂症、妄想状态。
     - 将恐惧症/躁狂症写回角色卡字段。
  5. 实现战斗、伤害与治疗状态
     - 记录重大伤口、昏迷、濒死状态。
     - 支持伤害结算、急救/医学治疗、自然恢复。
     - 实现基本战斗流程：DEX 顺序、近战反击/闪避、战技、寡不敌众、枪械攻击、故障。
     - 武器攻击可直接触发检定和伤害骰。
  6. 补全官方角色卡字段
     - 增加 Personal Description / Traits / Ideology & Beliefs / Injuries & Scars。
     - 增加 Significant People / Meaningful Locations / Treasured Possessions。
     - 增加 Encounters with Strange Entities / Phobias & Manias。
     - 增加 Arcane Tomes & Spells、备注、物品、外貌的完整编辑入口。
     - 同步更新 PDF 导出，确保字段覆盖官方角色卡。
  7. 实现角色成长
     - 技能成功后可勾选成长标记。
     - 幕间成长检定：失败则增加 `1D10`。
     - 成长后清除勾选，并保留成长记录。
  8. 实现魔法/典籍管理
     - 支持法术列表、典籍列表、学习记录。
     - 支持 MP/SAN 消耗、施法时间、首次施法 POW 检定、Push 施法。
  9. 完善非规则功能
     - 实现设置页深色模式开关。
     - 实现角色 JSON 导入/导出。
     - 实现清除全部数据功能。

- 在界面上面放一组骰子，点击骰子之后上面的数值会发生变化，提供快速的鉴定方案
- 检查骰子袋新版UI的逻辑是否有问题
- 考虑兼职的情况下 熟练加值的计算方式
- 临时生命值更好的修改方式


flutter pub run build_runner build

flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk


生成图标 flutter pub run flutter_launcher_icons:main

更换名称和图标 
https://juejin.cn/post/7220688635142455356

骰子图标
https://pixabay.com/zh/vectors/d20-dice-game-nat20-dnd-d-d-7136921/


open ios/Runner.xcworkspace
flutter build ios --release
