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