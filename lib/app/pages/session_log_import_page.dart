import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../data/session_log_message.dart';
import '../services/session_log_parser.dart';

class SessionLogImportPage extends StatefulWidget {
  const SessionLogImportPage({super.key});

  @override
  State<SessionLogImportPage> createState() => _SessionLogImportPageState();
}

class _SessionLogImportPageState extends State<SessionLogImportPage> {
  final _parser = const SessionLogParser();
  List<SessionLogMessage> _messages = const [];
  String? _sourceName;
  String? _sourceFormat;
  String? _me;
  bool _loading = false;

  Set<String> get _participants => _messages
      .where((message) => !message.isSystem)
      .map((message) => message.sender)
      .toSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('跑团 Log 转聊天'),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: '重新导入',
              icon: const Icon(Icons.add_to_photos_outlined),
              onPressed: _showImportMenu,
            ),
          if (_messages.isNotEmpty)
            IconButton(
              key: const Key('export_session_log'),
              tooltip: '导出',
              icon: const Icon(Icons.ios_share),
              onPressed: _showExportMenu,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? _buildImportLanding()
              : _buildConversation(),
    );
  }

  Widget _buildImportLanding() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child:
                    Icon(Icons.forum_outlined, size: 48, color: scheme.primary),
              ),
              const SizedBox(height: 24),
              Text('把跑团记录变成聊天记录',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(
                '自动识别时间、角色名、发言和旁白。所有解析都在本机完成。',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  key: const Key('pick_session_log_file'),
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('选择 Log 文档'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  key: const Key('paste_session_log'),
                  onPressed: _pasteText,
                  icon: const Icon(Icons.content_paste),
                  label: const Text('粘贴 Log 文本'),
                ),
              ),
              const SizedBox(height: 22),
              const Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  _FormatChip('TXT / LOG'),
                  _FormatChip('Markdown'),
                  _FormatChip('DOCX'),
                  _FormatChip('JSON'),
                  _FormatChip('CSV'),
                  _FormatChip('HTML'),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '支持「角色名：内容」「[时间] 角色名：内容」以及 QQ 导出记录等常见写法',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversation() {
    return Column(
      children: [
        _buildConversationHeader(),
        const Divider(height: 1),
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversationHeader() {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined,
                    size: 18, color: scheme.primary),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _sourceName ?? '粘贴内容',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${_sourceFormat ?? ''} · ${_messages.length} 条',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (_participants.isNotEmpty) ...[
              const SizedBox(height: 9),
              Row(
                children: [
                  Text('我的角色', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _participants.map((name) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(name),
                              selected: name == _me,
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) => setState(() => _me = name),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(int index) {
    final message = _messages[index];
    if (message.isSystem) {
      return GestureDetector(
        onTap: () => _editMessage(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                message.content,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      );
    }

    final mine = message.sender == _me;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!mine) ...[
            _Avatar(name: message.sender),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message.sender,
                        style: Theme.of(context).textTheme.bodySmall),
                    if (message.timestamp != null) ...[
                      const SizedBox(width: 7),
                      Text(_formatTime(message.timestamp!),
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _editMessage(index),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 620),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: mine ? scheme.primaryContainer : scheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(mine ? 16 : 4),
                        topRight: Radius.circular(mine ? 4 : 16),
                        bottomLeft: const Radius.circular(16),
                        bottomRight: const Radius.circular(16),
                      ),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: SelectableText(message.content),
                  ),
                ),
              ],
            ),
          ),
          if (mine) ...[
            const SizedBox(width: 9),
            _Avatar(name: message.sender, emphasized: true),
          ],
        ],
      ),
    );
  }

  void _showImportMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('选择另一份文档'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste),
              title: const Text('粘贴另一份文本'),
              onTap: () {
                Navigator.pop(context);
                _pasteText();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? selection;
    try {
      selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: SessionLogParser.supportedExtensions,
        withData: true,
      );
    } catch (error) {
      if (mounted) _showError('无法打开文件选择器：$error');
      return;
    }
    if (selection == null || selection.files.isEmpty) return;

    final file = selection.files.single;
    setState(() => _loading = true);
    try {
      final bytes = file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null) throw const FormatException('无法读取文件内容');
      final result = _parser.parseBytes(Uint8List.fromList(bytes), file.name);
      _applyResult(result, file.name);
    } on FormatException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError('导入失败：$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pasteText() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final controller = TextEditingController(text: clipboard?.text ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('粘贴 Log 文本'),
        content: SizedBox(
          width: 560,
          child: TextField(
            key: const Key('session_log_text_input'),
            controller: controller,
            autofocus: true,
            minLines: 10,
            maxLines: 18,
            decoration: const InputDecoration(
              hintText: '[21:30] 调查员：我推开了那扇门……',
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('生成聊天'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty || !mounted) return;
    _applyResult(_parser.parseText(text), '粘贴内容');
  }

  void _applyResult(SessionLogParseResult result, String sourceName) {
    if (result.messages.isEmpty) {
      _showError('没有识别到可展示的消息，请检查文档内容');
      return;
    }
    setState(() {
      _messages = result.messages;
      _sourceName = sourceName;
      _sourceFormat = result.sourceFormat;
      final participants = result.participants;
      _me = participants.length == 1 ? participants.first : null;
    });
    if (result.warning != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.warning!)));
    }
  }

  Future<void> _editMessage(int index) async {
    final original = _messages[index];
    final sender = TextEditingController(text: original.sender);
    final content = TextEditingController(text: original.content);
    var isSystem = original.isSystem;
    final result = await showDialog<_EditResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('修正消息'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: sender,
                  enabled: !isSystem,
                  decoration: const InputDecoration(labelText: '角色名'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: content,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: '内容'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('作为旁白 / 系统消息'),
                  value: isSystem,
                  onChanged: (value) =>
                      setDialogState(() => isSystem = value ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () =>
                  Navigator.pop(context, const _EditResult.delete()),
              child: const Text('删除'),
            ),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消')),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                _EditResult(
                  message: original.copyWith(
                    sender: isSystem ? '旁白' : sender.text.trim(),
                    content: content.text.trim(),
                    isSystem: isSystem,
                  ),
                ),
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    sender.dispose();
    content.dispose();
    if (result == null || !mounted) return;
    setState(() {
      final updated = [..._messages];
      if (result.shouldDelete) {
        updated.removeAt(index);
      } else if (result.message != null && result.message!.content.isNotEmpty) {
        updated[index] = result.message!;
      }
      _messages = updated;
      if (!_participants.contains(_me)) _me = null;
    });
  }

  void _showExportMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.web),
              title: const Text('保存聊天样式 HTML'),
              subtitle: const Text('浏览器打开即可查看或打印'),
              onTap: () {
                Navigator.pop(context);
                _saveHtml();
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('复制聊天文本'),
              onTap: () {
                Navigator.pop(context);
                _copyText();
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('复制结构化 JSON'),
              onTap: () {
                Navigator.pop(context);
                _copyJson();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyText() async {
    final text = _messages.map((message) {
      final time = message.timestamp == null
          ? ''
          : '[${_formatTime(message.timestamp!)}] ';
      return message.isSystem
          ? '$time${message.content}'
          : '$time${message.sender}：${message.content}';
    }).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _showInfo('聊天文本已复制');
  }

  Future<void> _copyJson() async {
    final text = const JsonEncoder.withIndent('  ').convert(
      _messages.map((message) => message.toJson()).toList(),
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _showInfo('JSON 已复制');
  }

  Future<void> _saveHtml() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stamp =
          DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
      final file = File('${directory.path}/coccard_chat_$stamp.html');
      await file.writeAsString(_buildHtml(), flush: true);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('聊天记录已导出'),
          content: SelectableText('文件位置：\n${file.path}'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('知道了')),
          ],
        ),
      );
    } catch (error) {
      if (mounted) _showError('保存失败：$error');
    }
  }

  String _buildHtml() {
    final rows = _messages.map((message) {
      if (message.isSystem) {
        return '<div class="system">${_escapeHtml(message.content)}</div>';
      }
      final mine = message.sender == _me;
      final time =
          message.timestamp == null ? '' : _formatTime(message.timestamp!);
      return '<div class="row ${mine ? 'mine' : ''}">'
          '<div class="avatar">${_escapeHtml(_initial(message.sender))}</div>'
          '<div class="message"><div class="meta">${_escapeHtml(message.sender)} $time</div>'
          '<div class="bubble">${_escapeHtml(message.content).replaceAll('\n', '<br>')}</div></div></div>';
    }).join();
    return '''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>${_escapeHtml(_sourceName ?? '跑团聊天记录')}</title>
<style>body{margin:0;background:#e9eee9;color:#24322c;font:15px/1.6 system-ui,-apple-system,"PingFang SC",sans-serif}.page{max-width:820px;margin:auto;min-height:100vh;background:#f5f2e9}.header{position:sticky;top:0;background:#1b4332;color:white;padding:18px 24px;font-size:18px;font-weight:700;box-shadow:0 2px 8px #0002}.chat{padding:24px}.row{display:flex;gap:10px;align-items:flex-start;margin:0 0 18px}.row.mine{flex-direction:row-reverse}.avatar{display:grid;place-items:center;flex:0 0 38px;height:38px;border-radius:12px;background:#b08d57;color:white;font-weight:700}.message{max-width:72%}.meta{font-size:12px;color:#718078;margin:0 3px 4px}.mine .meta{text-align:right}.bubble{background:white;border:1px solid #d9e0da;border-radius:4px 16px 16px;padding:9px 13px;box-shadow:0 1px 2px #0000000d}.mine .bubble{background:#d4e8df;border-radius:16px 4px 16px 16px}.system{width:fit-content;max-width:75%;margin:12px auto;padding:5px 12px;background:#dde3de;border-radius:8px;color:#66736c;font-size:13px;text-align:center}@media print{.header{position:static}.page{max-width:none}.chat{padding:12px}}</style></head>
<body><main class="page"><header class="header">${_escapeHtml(_sourceName ?? '跑团聊天记录')} · ${_messages.length} 条消息</header><section class="chat">$rows</section></main></body></html>''';
  }

  String _escapeHtml(String value) => const HtmlEscape().convert(value);

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error),
      );

  void _showInfo(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  static String _formatTime(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    final local = value.toLocal();
    return '${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}

class _FormatChip extends StatelessWidget {
  const _FormatChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: const Icon(Icons.check_circle_outline, size: 16),
        label: Text(label),
        visualDensity: VisualDensity.compact,
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.emphasized = false});
  final String name;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 19,
      backgroundColor: emphasized ? scheme.primary : scheme.secondary,
      foregroundColor: emphasized ? scheme.onPrimary : scheme.onSecondary,
      child: Text(_initial(name),
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

String _initial(String name) {
  final clean = name.trim();
  return clean.isEmpty ? '?' : clean.characters.first.toUpperCase();
}

class _EditResult {
  const _EditResult({this.message}) : shouldDelete = false;
  const _EditResult.delete()
      : message = null,
        shouldDelete = true;

  final SessionLogMessage? message;
  final bool shouldDelete;
}
