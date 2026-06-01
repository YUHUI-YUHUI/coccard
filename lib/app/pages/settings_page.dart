import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/character_manager.dart';
import '../services/image_generator.dart';
import '../setting/app_pref.dart';
import '../setting/theme_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const MethodChannel _backupChannel = MethodChannel('coccard/backup');

  final TextEditingController _apiKeyCtrl = TextEditingController();
  bool _obscureKey = true;

  // 图像生成配置
  ImageGenProvider _imageProvider = ImageGenProvider.stub;
  final TextEditingController _imageApiKeyCtrl = TextEditingController();
  final TextEditingController _imageModelCtrl = TextEditingController();
  bool _obscureImageKey = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final appPref = AppPreferences(prefs);
    setState(() {
      _apiKeyCtrl.text = appPref.getDeepseekApiKey();
      _imageProvider = ImageGenProvider.fromKey(appPref.getImageProvider());
      _imageApiKeyCtrl.text = appPref.getImageApiKey();
      _imageModelCtrl.text = appPref.getImageModel();
    });
  }

  Future<void> _saveImageSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final appPref = AppPreferences(prefs);
    await appPref.setImageProvider(_imageProvider.name);
    await appPref.setImageApiKey(_imageApiKeyCtrl.text.trim());
    await appPref.setImageModel(_imageModelCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('图像生成设置已保存')),
      );
    }
  }

  Future<void> _saveApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final appPref = AppPreferences(prefs);
    await appPref.setDeepseekApiKey(_apiKeyCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key 已保存')),
      );
    }
  }

  Future<void> _exportCharacters() async {
    final manager = context.read<CharacterManager>();
    if (!manager.hasCharacters) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前没有可导出的角色卡')),
      );
      return;
    }

    final backupJson = manager.exportCharactersBackupJson();
    await Clipboard.setData(ClipboardData(text: backupJson));

    String? filePath;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final file = File('${directory.path}/coccard_backup_$timestamp.json');
      await file.writeAsString(backupJson);
      filePath = file.path;
    } catch (_) {
      filePath = null;
    }

    var shared = false;
    try {
      await _backupChannel.invokeMethod<void>('shareText', {
        'title': 'COC 角色卡备份',
        'text': backupJson,
      });
      shared = true;
    } catch (_) {
      shared = false;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(shared ? '备份 JSON 已复制，并已打开分享' : '备份 JSON 已复制到剪贴板'),
      ),
    );

    if (filePath != null && mounted) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('备份已保存'),
          content: SelectableText('文件位置：\n$filePath'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
    }
  }

  void _showImportDialog() {
    final jsonCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入角色'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: jsonCtrl,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: '粘贴导出的 JSON 备份内容',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                final text =
                    await _backupChannel.invokeMethod<String>('pickJsonText');
                if (text != null && text.isNotEmpty) {
                  jsonCtrl.text = text;
                }
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('当前平台不支持选择文件，请粘贴 JSON')),
                );
              }
            },
            child: const Text('选择文件'),
          ),
          TextButton(
            onPressed: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              jsonCtrl.text = data?.text ?? '';
            },
            child: const Text('粘贴'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => _importCharacters(
              dialogContext,
              jsonCtrl.text,
              replaceExisting: false,
            ),
            child: const Text('追加'),
          ),
          ElevatedButton(
            onPressed: () =>
                _confirmReplaceImport(dialogContext, jsonCtrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('覆盖'),
          ),
        ],
      ),
    ).then((_) => jsonCtrl.dispose());
  }

  void _confirmReplaceImport(BuildContext importDialogContext, String rawJson) {
    showDialog<void>(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: const Text('覆盖现有角色？'),
        content: const Text('覆盖导入会先清空当前角色卡，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(confirmContext);
              await _importCharacters(
                importDialogContext,
                rawJson,
                replaceExisting: true,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('确认覆盖'),
          ),
        ],
      ),
    );
  }

  Future<void> _importCharacters(
    BuildContext dialogContext,
    String rawJson, {
    required bool replaceExisting,
  }) async {
    final trimmed = rawJson.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先粘贴 JSON 备份内容')),
      );
      return;
    }

    try {
      final count =
          await context.read<CharacterManager>().importCharactersBackupJson(
                trimmed,
                replaceExisting: replaceExisting,
              );
      if (!dialogContext.mounted) return;
      Navigator.pop(dialogContext);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导入 $count 张角色卡')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败：$e')),
      );
    }
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _imageApiKeyCtrl.dispose();
    _imageModelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          Consumer<ThemeController>(
            builder: (context, themeController, _) {
              final darkModeEnabled = themeController.darkModeEnabled;
              return SwitchListTile(
                secondary: Icon(
                  darkModeEnabled ? Icons.dark_mode : Icons.light_mode,
                ),
                title: const Text('深色模式'),
                subtitle: Text(darkModeEnabled ? '已使用深色主题' : '开启后将使用深色主题'),
                value: darkModeEnabled,
                onChanged: themeController.setDarkModeEnabled,
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('导出角色'),
            subtitle: const Text('复制 JSON，并打开系统分享'),
            onTap: _exportCharacters,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('导入角色'),
            subtitle: const Text('粘贴 JSON，可追加或覆盖当前角色'),
            onTap: _showImportDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('清除所有数据'),
            subtitle: const Text('删除所有角色和设置'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认清除'),
                  content: const Text('确定要清除所有数据吗？此操作不可恢复。',
                      style: TextStyle(color: Colors.red)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消')),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('清除数据功能开发中')));
                      },
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('确认清除'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('AI 设置', style: Theme.of(context).textTheme.titleSmall),
          ),
          // API Key input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _apiKeyCtrl,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      labelText: 'DeepSeek API Key',
                      hintText: 'sk-...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureKey
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _saveApiKey, child: const Text('保存')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('头像图像生成', style: Theme.of(context).textTheme.titleSmall),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<ImageGenProvider>(
              value: _imageProvider,
              decoration: const InputDecoration(
                labelText: '图像服务提供商',
                border: OutlineInputBorder(),
              ),
              items: ImageGenProvider.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _imageProvider = v);
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _imageApiKeyCtrl,
              obscureText: _obscureImageKey,
              decoration: InputDecoration(
                labelText: '图像服务 API Key',
                hintText: _imageProvider == ImageGenProvider.stub ? '请先选择提供商' : '粘贴对应的 API Key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureImageKey ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureImageKey = !_obscureImageKey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _imageModelCtrl,
              decoration: InputDecoration(
                labelText: '模型（留空使用默认）',
                hintText: _imageProvider == ImageGenProvider.siliconflow
                    ? 'black-forest-labs/FLUX.1-schnell'
                    : (_imageProvider == ImageGenProvider.zhipu ? 'cogview-4' : ''),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _saveImageSettings,
                child: const Text('保存图像设置'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('关于'),
            subtitle: Text('COC 角色卡 v1.0.0'),
          ),
        ],
      ),
    );
  }
}
