import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:coc_character/app/services/session_log_parser.dart';

void main() {
  const parser = SessionLogParser();

  group('SessionLogParser text', () {
    test('parses common timestamp, sender and multiline messages', () {
      final result = parser.parseText('''
[2026-07-18 20:10] 调查员：我检查书架。
这里似乎有夹层。
[20:11] <守秘人> 进行一次图书馆使用检定。
【调查员】1D100=23，成功！
''');

      expect(result.messages, hasLength(3));
      expect(result.messages.first.sender, '调查员');
      expect(result.messages.first.content, contains('夹层'));
      expect(result.messages[1].sender, '守秘人');
      expect(result.messages[2].content, '1D100=23，成功！');
      expect(result.participants, {'调查员', '守秘人'});
    });

    test('preserves unrecognized prose as narration', () {
      final result = parser.parseText('夜色笼罩了阿卡姆。\n调查员：我们出发吧。');

      expect(result.messages, hasLength(2));
      expect(result.messages.first.isSystem, isTrue);
      expect(result.messages.first.sender, '旁白');
      expect(result.warning, isNotNull);
    });

    test('parses QQ style exported log', () {
      final result = parser.parseText('''
2026-07-18 20:10:03 林恩(123456)
我打开手电。
2026-07-18 20:10:10 守秘人<987654>
走廊尽头传来脚步声。
''');

      expect(result.messages, hasLength(2));
      expect(result.messages.first.sender, '林恩');
      expect(result.messages.last.sender, '守秘人');
      expect(result.messages.first.timestamp, isNotNull);
    });
  });

  test('parses flexible JSON field names', () {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
      'messages': [
        {'name': '安娜', 'text': '有人在吗？', 'time': '2026-07-18 21:00:00'},
        {'role': 'KP', 'message': '没有回应。'},
      ],
    })));
    final result = parser.parseBytes(bytes, 'session.json');

    expect(result.sourceFormat, 'JSON');
    expect(result.messages.map((message) => message.sender), ['安娜', 'KP']);
  });

  test('parses Chinese CSV headers and quoted comma', () {
    final bytes = Uint8List.fromList(
      utf8.encode('时间,角色名,内容\n2026-07-18 21:00,安娜,"等等,先别开门"'),
    );
    final result = parser.parseBytes(bytes, 'session.csv');

    expect(result.messages, hasLength(1));
    expect(result.messages.single.sender, '安娜');
    expect(result.messages.single.content, '等等,先别开门');
  });

  test('strips basic HTML before parsing', () {
    final bytes = Uint8List.fromList(
      utf8.encode('<p>调查员：查看窗外。</p><p>KP：雾越来越浓了。</p>'),
    );
    final result = parser.parseBytes(bytes, 'session.html');

    expect(result.messages, hasLength(2));
    expect(result.messages.last.sender, 'KP');
  });
}
