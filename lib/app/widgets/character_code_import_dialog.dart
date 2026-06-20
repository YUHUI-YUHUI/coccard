import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/character.dart';
import '../data/character_manager.dart';

Future<Character?> showCharacterCodeImportDialog(BuildContext context) {
  return showDialog<Character>(
    context: context,
    builder: (_) => const CharacterCodeImportDialog(),
  );
}

class CharacterCodeImportDialog extends StatefulWidget {
  const CharacterCodeImportDialog({super.key});

  @override
  State<CharacterCodeImportDialog> createState() =>
      _CharacterCodeImportDialogState();
}

class _CharacterCodeImportDialogState extends State<CharacterCodeImportDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isImporting = false;
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    setState(() {
      _codeController.text = data?.text?.trim() ?? '';
      _errorText = null;
    });
  }

  Future<void> _import() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorText = '请先粘贴角色码');
      return;
    }

    setState(() {
      _isImporting = true;
      _errorText = null;
    });
    try {
      final character =
          await context.read<CharacterManager>().importCharacterShareCode(code);
      if (mounted) Navigator.pop(context, character);
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _errorText = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _errorText = '导入失败，请检查角色码后重试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('粘贴角色码'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('粘贴其他玩家分享的角色码，即可获取完整人物卡信息。'),
            const SizedBox(height: 16),
            TextField(
              key: const Key('character_share_code_field'),
              controller: _codeController,
              enabled: !_isImporting,
              minLines: 4,
              maxLines: 8,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'COCCARD1.eyJzY2hlbWEiOi...',
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _isImporting ? null : _pasteFromClipboard,
              icon: const Icon(Icons.content_paste),
              label: const Text('从剪贴板粘贴'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          key: const Key('import_character_share_code_button'),
          onPressed: _isImporting ? null : _import,
          child: _isImporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('导入人物卡'),
        ),
      ],
    );
  }
}
