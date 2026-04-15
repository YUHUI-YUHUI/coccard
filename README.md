# coccard

克苏鲁的呼唤 第七版 角色卡应用

一款基于 Flutter 构建的在线角色卡应用，兼容移动端与桌面端。

![Screenshot](./screenshot/1028-4.png)


## TODO

- [x] 数据持久化存储
- [x] 技能检定及对应加成/减值
- [ ] 战役笔记
- [x] 法术书
- [x] 快速消耗品栏
- [ ] 协助创建角色卡的工具

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
