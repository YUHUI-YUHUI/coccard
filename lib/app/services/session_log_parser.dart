import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../data/session_log_message.dart';

class SessionLogParseResult {
  const SessionLogParseResult({
    required this.messages,
    required this.sourceFormat,
    this.warning,
  });

  final List<SessionLogMessage> messages;
  final String sourceFormat;
  final String? warning;

  Set<String> get participants => messages
      .where((message) => !message.isSystem)
      .map((message) => message.sender)
      .where((name) => name.isNotEmpty)
      .toSet();
}

/// Converts common tabletop-RPG log formats into a shared chat message model.
class SessionLogParser {
  const SessionLogParser();

  static const supportedExtensions = <String>[
    'txt',
    'log',
    'md',
    'csv',
    'json',
    'html',
    'htm',
    'docx',
  ];

  SessionLogParseResult parseBytes(Uint8List bytes, String fileName) {
    final extension =
        fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'txt';
    if (extension == 'docx') {
      return parseText(_readDocx(bytes), sourceFormat: 'DOCX');
    }

    final text = _decodeText(bytes);
    switch (extension) {
      case 'json':
        return _parseJson(text);
      case 'csv':
        return _parseCsv(text);
      case 'html':
      case 'htm':
        return parseText(_htmlToText(text), sourceFormat: 'HTML');
      case 'md':
        return parseText(_stripMarkdown(text), sourceFormat: 'Markdown');
      case 'log':
        return parseText(text, sourceFormat: 'LOG');
      default:
        return parseText(text, sourceFormat: 'TXT');
    }
  }

  SessionLogParseResult parseText(
    String input, {
    String sourceFormat = '粘贴文本',
  }) {
    final text = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (text.isEmpty) {
      return SessionLogParseResult(
          messages: const [], sourceFormat: sourceFormat);
    }

    final messages = <SessionLogMessage>[];
    SessionLogMessage? current;
    final qqHeader = RegExp(
      r'^(\d{4}[-/.年]\d{1,2}[-/.月]\d{1,2}日?\s+\d{1,2}:\d{2}(?::\d{2})?)\s+(.+?)(?:\(\d+\)|<\d+>)?\s*$',
    );

    void commit() {
      if (current != null && current!.content.trim().isNotEmpty) {
        messages.add(current!.copyWith(content: current!.content.trim()));
      }
      current = null;
    }

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) {
        if (current != null && !current!.content.endsWith('\n')) {
          current = current!.copyWith(content: '${current!.content}\n');
        }
        continue;
      }

      final qq = qqHeader.firstMatch(line.trim());
      if (qq != null) {
        commit();
        current = SessionLogMessage(
          sender: _cleanSender(qq.group(2)!),
          content: '',
          timestamp: _parseDate(qq.group(1)),
        );
        continue;
      }

      final parsed = _parseChatLine(line);
      if (parsed != null) {
        commit();
        current = parsed;
        continue;
      }

      if (current != null) {
        final separator = current!.content.isEmpty ? '' : '\n';
        current = current!
            .copyWith(content: '${current!.content}$separator${line.trim()}');
      } else {
        messages.add(SessionLogMessage(
          sender: '旁白',
          content: line.trim(),
          isSystem: true,
        ));
      }
    }
    commit();

    return SessionLogParseResult(
      messages: _mergeAdjacentSystemMessages(messages),
      sourceFormat: sourceFormat,
      warning: messages.any((message) => message.isSystem)
          ? '部分段落未识别到发言者，已作为旁白保留'
          : null,
    );
  }

  SessionLogMessage? _parseChatLine(String line) {
    final patterns = <RegExp>[
      RegExp(r'^\[(.+?)\]\s*[<【](.+?)[>】]\s*[:：]?\s*(.+)$'),
      RegExp(r'^\[(.+?)\]\s*([^:：]{1,40})\s*[:：]\s*(.+)$'),
      RegExp(r'^[<【]([^>】]{1,40})[>】]\s*[:：]?\s*(.+)$'),
      RegExp(r'^([^:：\[\]【】]{1,40})\s*[:：]\s*(.+)$'),
    ];

    for (var index = 0; index < patterns.length; index++) {
      final match = patterns[index].firstMatch(line.trim());
      if (match == null) continue;
      if (index <= 1) {
        return SessionLogMessage(
          sender: _cleanSender(match.group(2)!),
          content: match.group(3)!.trim(),
          timestamp: _parseDate(match.group(1)),
        );
      }
      return SessionLogMessage(
        sender: _cleanSender(match.group(1)!),
        content: match.group(2)!.trim(),
      );
    }
    return null;
  }

  SessionLogParseResult _parseJson(String text) {
    try {
      final decoded = jsonDecode(text);
      final dynamic rawList = decoded is List
          ? decoded
          : decoded is Map
              ? decoded['messages'] ??
                  decoded['logs'] ??
                  decoded['records'] ??
                  decoded['data']
              : null;
      if (rawList is! List) throw const FormatException('找不到消息数组');

      final messages = <SessionLogMessage>[];
      for (final item in rawList) {
        if (item is String) {
          messages.addAll(parseText(item).messages);
          continue;
        }
        if (item is! Map) continue;
        final sender = _firstString(item, const [
              'sender',
              'name',
              'nickname',
              'user',
              'character',
              'role'
            ]) ??
            '旁白';
        final content = _firstString(
          item,
          const ['content', 'message', 'text', 'body'],
        );
        if (content == null || content.trim().isEmpty) continue;
        final time = _firstString(
          item,
          const ['timestamp', 'time', 'date', 'createdAt'],
        );
        messages.add(SessionLogMessage(
          sender: sender,
          content: content.trim(),
          timestamp: _parseDate(time),
          isSystem: sender == '旁白' || sender.toLowerCase() == 'system',
        ));
      }
      return SessionLogParseResult(messages: messages, sourceFormat: 'JSON');
    } on FormatException catch (error) {
      throw FormatException('JSON 解析失败：${error.message}');
    }
  }

  SessionLogParseResult _parseCsv(String text) {
    final rows = _csvRows(text);
    if (rows.isEmpty) {
      return const SessionLogParseResult(messages: [], sourceFormat: 'CSV');
    }
    final header = rows.first.map((cell) => cell.trim().toLowerCase()).toList();
    int column(List<String> names) {
      for (final name in names) {
        final found = header.indexOf(name);
        if (found >= 0) return found;
      }
      return -1;
    }

    final senderIndex =
        column(const ['sender', 'name', '角色', '角色名', '发言人', '昵称']);
    final contentIndex =
        column(const ['content', 'message', 'text', '内容', '消息', '发言']);
    final timeIndex = column(const ['timestamp', 'time', 'date', '时间', '日期']);
    final hasHeader = senderIndex >= 0 || contentIndex >= 0;
    final messages = <SessionLogMessage>[];
    for (final row in rows.skip(hasHeader ? 1 : 0)) {
      if (row.every((cell) => cell.trim().isEmpty)) continue;
      final sIndex = senderIndex >= 0 ? senderIndex : 0;
      final cIndex =
          contentIndex >= 0 ? contentIndex : (row.length > 1 ? 1 : 0);
      if (cIndex >= row.length) continue;
      final sender = sIndex < row.length && row[sIndex].trim().isNotEmpty
          ? row[sIndex].trim()
          : '旁白';
      messages.add(SessionLogMessage(
        sender: sender,
        content: row[cIndex].trim(),
        timestamp: timeIndex >= 0 && timeIndex < row.length
            ? _parseDate(row[timeIndex])
            : null,
        isSystem: sender == '旁白',
      ));
    }
    return SessionLogParseResult(messages: messages, sourceFormat: 'CSV');
  }

  List<List<String>> _csvRows(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var quoted = false;
    for (var index = 0; index < input.length; index++) {
      final char = input[index];
      if (char == '"') {
        if (quoted && index + 1 < input.length && input[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (char == ',' && !quoted) {
        row.add(field.toString());
        field = StringBuffer();
      } else if ((char == '\n' || char == '\r') && !quoted) {
        if (char == '\r' &&
            index + 1 < input.length &&
            input[index + 1] == '\n') index++;
        row.add(field.toString());
        rows.add(row);
        row = <String>[];
        field = StringBuffer();
      } else {
        field.write(char);
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }

  String _readDocx(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final document =
          archive.files.where((file) => file.name == 'word/document.xml').first;
      final xmlBytes = document.content;
      final xml =
          XmlDocument.parse(utf8.decode(xmlBytes, allowMalformed: true));
      return xml.descendants
          .whereType<XmlElement>()
          .where((node) => node.name.local == 'p')
          .map((paragraph) => paragraph.descendants
              .whereType<XmlElement>()
              .where((node) => node.name.local == 't')
              .map((node) => node.innerText)
              .join())
          .where((paragraph) => paragraph.trim().isNotEmpty)
          .join('\n');
    } catch (_) {
      throw const FormatException('DOCX 解析失败，请确认文件未损坏且不是旧版 .doc 文件');
    }
  }

  String _decodeText(Uint8List bytes) {
    final cleanBytes = bytes.length >= 3 &&
            bytes[0] == 0xef &&
            bytes[1] == 0xbb &&
            bytes[2] == 0xbf
        ? bytes.sublist(3)
        : bytes;
    try {
      return utf8.decode(cleanBytes);
    } on FormatException {
      return utf8.decode(cleanBytes, allowMalformed: true);
    }
  }

  String _stripMarkdown(String text) => text
      .replaceAll(RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*>\s?', multiLine: true), '')
      .replaceAll(RegExp(r'\*\*|__|~~|`'), '');

  String _htmlToText(String html) => html
      .replaceAll(
          RegExp(r'<(script|style)[^>]*>[\s\S]*?</\1>', caseSensitive: false),
          '')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(
          RegExp(r'</(p|div|li|tr|h[1-6])>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");

  List<SessionLogMessage> _mergeAdjacentSystemMessages(
      List<SessionLogMessage> input) {
    final result = <SessionLogMessage>[];
    for (final message in input) {
      if (message.isSystem && result.isNotEmpty && result.last.isSystem) {
        final previous = result.removeLast();
        result.add(previous.copyWith(
            content: '${previous.content}\n${message.content}'));
      } else {
        result.add(message);
      }
    }
    return result;
  }

  String _cleanSender(String value) =>
      value.replaceFirst(RegExp(r'\s*(?:\(\d+\)|<\d+>)\s*$'), '').trim();

  String? _firstString(Map<dynamic, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null) return value.toString();
    }
    return null;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    var normalized = value
        .trim()
        .replaceAll('年', '-')
        .replaceAll('月', '-')
        .replaceAll('日', '')
        .replaceAll('/', '-')
        .replaceAll('.', '-');
    if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(normalized)) {
      final now = DateTime.now();
      normalized = '${now.year}-${now.month}-${now.day} $normalized';
    }
    return DateTime.tryParse(normalized.replaceFirst(' ', 'T'));
  }
}
