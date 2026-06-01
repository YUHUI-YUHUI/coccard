import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/character.dart';
import '../data/character_manager.dart';
import '../services/avatar_storage.dart';
import '../services/image_generator.dart';
import '../setting/app_pref.dart';

/// 圆形头像。点击触发 [showAvatarActionSheet]。
class AvatarWidget extends StatelessWidget {
  final double size;
  final bool tappable;
  const AvatarWidget({super.key, this.size = 72, this.tappable = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<CharacterManager>(
      builder: (context, manager, _) {
        final c = manager.character;
        final image = _resolveImage(c);
        final widget = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              width: 1.5,
            ),
            image: image == null ? null : DecorationImage(image: image, fit: BoxFit.cover),
          ),
          child: image == null
              ? Icon(Icons.person, size: size * 0.55, color: Theme.of(context).colorScheme.onSurfaceVariant)
              : null,
        );
        if (!tappable) return widget;
        return InkWell(
          customBorder: const CircleBorder(),
          onTap: () => showAvatarActionSheet(context),
          child: widget,
        );
      },
    );
  }

  static ImageProvider? _resolveImage(Character c) {
    if (c.avatarLocalPath != null && c.avatarLocalPath!.isNotEmpty) {
      final f = File(c.avatarLocalPath!);
      if (f.existsSync()) return FileImage(f);
    }
    if (c.avatarUrl != null && c.avatarUrl!.startsWith('http')) {
      return NetworkImage(c.avatarUrl!);
    }
    return null;
  }
}

/// 弹出底部操作面板：AI 生成 / 从相册选 / 清除。
Future<void> showAvatarActionSheet(BuildContext context) async {
  final manager = context.read<CharacterManager>();
  final hasAvatar = (manager.character.avatarLocalPath ?? '').isNotEmpty ||
      (manager.character.avatarUrl ?? '').isNotEmpty;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('AI 生成头像'),
              subtitle: const Text('根据角色信息生成图像'),
              onTap: () async {
                Navigator.pop(ctx);
                await showAvatarAiDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickFromGallery(context);
              },
            ),
            if (hasAvatar)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('清除头像', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await AvatarStorage.deleteIfExists(manager.character.avatarLocalPath);
                  manager.setAvatar(localPath: null, url: null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<void> _pickFromGallery(BuildContext context) async {
  final manager = context.read<CharacterManager>();
  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final oldPath = manager.character.avatarLocalPath;
    final localPath = await AvatarStorage.importFile(
      characterId: manager.character.id,
      sourcePath: picked.path,
    );
    manager.setAvatar(localPath: localPath, url: null);
    await AvatarStorage.deleteIfExists(oldPath);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('选择失败: $e')));
    }
  }
}

/// AI 头像生成对话框。
Future<void> showAvatarAiDialog(BuildContext context) async {
  final manager = context.read<CharacterManager>();
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return;
  final appPref = AppPreferences(prefs);
  final providerKey = appPref.getImageProvider();
  final provider = ImageGenProvider.fromKey(providerKey);

  if (provider == ImageGenProvider.stub) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('请先在设置页选择图像生成服务并配置 API Key'),
        action: SnackBarAction(
          label: '去设置',
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
      ),
    );
    return;
  }

  final defaultPrompt = _buildDefaultPrompt(manager.character);
  final promptCtrl = TextEditingController(text: defaultPrompt);
  final modelCtrl = TextEditingController(text: appPref.getImageModel());

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return _AvatarAiDialog(
        provider: provider,
        apiKey: appPref.getImageApiKey(),
        promptCtrl: promptCtrl,
        modelCtrl: modelCtrl,
        characterId: manager.character.id,
        onSaved: (localPath, url) async {
          final oldPath = manager.character.avatarLocalPath;
          manager.setAvatar(localPath: localPath, url: url);
          await AvatarStorage.deleteIfExists(oldPath);
        },
      );
    },
  );
}

String _buildDefaultPrompt(Character c) {
  final parts = <String>[];
  parts.add('Cthulhu 1920s investigator portrait');
  if (c.gender.isNotEmpty) parts.add(c.gender);
  if (c.age.isNotEmpty) parts.add('${c.age} years old');
  if (c.occupation.isNotEmpty) parts.add(c.occupation);
  if (c.appearance.isNotEmpty) parts.add(c.appearance);
  parts.add('moody lighting, oil painting style, head and shoulders');
  return parts.join(', ');
}

class _AvatarAiDialog extends StatefulWidget {
  final ImageGenProvider provider;
  final String apiKey;
  final TextEditingController promptCtrl;
  final TextEditingController modelCtrl;
  final int characterId;
  final Future<void> Function(String localPath, String url) onSaved;

  const _AvatarAiDialog({
    required this.provider,
    required this.apiKey,
    required this.promptCtrl,
    required this.modelCtrl,
    required this.characterId,
    required this.onSaved,
  });

  @override
  State<_AvatarAiDialog> createState() => _AvatarAiDialogState();
}

class _AvatarAiDialogState extends State<_AvatarAiDialog> {
  bool _loading = false;
  String? _previewLocalPath;
  String? _previewUrl;
  String? _error;

  Future<void> _generate() async {
    final prompt = widget.promptCtrl.text.trim();
    if (prompt.isEmpty) {
      setState(() => _error = '请输入提示词');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final generator = ImageGeneratorFactory.create(
        provider: widget.provider,
        apiKey: widget.apiKey,
        model: widget.modelCtrl.text.trim().isEmpty ? null : widget.modelCtrl.text.trim(),
      );
      final result = await generator.generate(prompt);

      String localPath;
      if (result.bytes != null && result.bytes!.isNotEmpty) {
        localPath = await AvatarStorage.saveBytes(
          characterId: widget.characterId,
          bytes: result.bytes!,
        );
      } else if (result.url.isNotEmpty) {
        localPath = await AvatarStorage.downloadAndSave(
          characterId: widget.characterId,
          url: result.url,
        );
      } else {
        throw ImageGenerationException('未拿到图像数据');
      }
      if (!mounted) return;
      setState(() {
        _previewLocalPath = localPath;
        _previewUrl = result.url;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('AI 生成头像（${widget.provider.label}）'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('提示词', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: widget.promptCtrl,
                maxLines: 4,
                minLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 12),
              const Text('模型（可留空使用默认）', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: widget.modelCtrl,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (_previewLocalPath != null)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_previewLocalPath!), width: 240, height: 240, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 8),
                    Text('已下载到本地', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        if (_previewLocalPath != null)
          TextButton(
            onPressed: _loading ? null : _generate,
            child: const Text('重新生成'),
          ),
        ElevatedButton(
          onPressed: _loading
              ? null
              : (_previewLocalPath != null
                  ? () async {
                      final navigator = Navigator.of(context);
                      await widget.onSaved(_previewLocalPath!, _previewUrl ?? '');
                      if (mounted) navigator.pop();
                    }
                  : _generate),
          child: Text(_previewLocalPath != null ? '保存' : '生成'),
        ),
      ],
    );
  }
}
