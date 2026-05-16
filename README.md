# coccard

克苏鲁的呼唤 第七版 角色卡应用

一款基于 Flutter 构建的在线角色卡应用，兼容移动端与桌面端。

## 功能特点

- 角色创建与编辑
- 属性自动计算
- 技能点分配
- 角色卡 PDF 导出
- 深色/浅色主题切换
- 数据持久化存储

## 技术栈

- Flutter 3.24+
- Dart 3.5+
- shared_preferences（数据持久化）
- pdf（PDF 生成）

## 如何编译

编译前请确保已安装以下环境：

1. **Flutter 版本**: 项目需要 Flutter `3.24.0`，Dart `3.5.0`。运行以下命令检查版本：
   ```bash
   flutter --version
   ```
   如需安装，请前往 [Flutter 官网](https://flutter.dev) 下载。

2. **支持的平台**: 项目支持 **Android** 和 **iOS** 平台。

### 编译步骤

1. 克隆仓库：
   ```bash
   git clone https://github.com/YUHUI-YUHUI/coccard
   cd coccard
   ```

2. 获取依赖：
   ```bash
   flutter pub get
   ```

3. 编译 Android：
   ```bash
   flutter build apk
   ```

4. 编译 iOS（需要 macOS 和 Xcode）：
   ```bash
   flutter build ios
   ```

更多详情请参阅 [Flutter 文档](https://flutter.dev/docs)。