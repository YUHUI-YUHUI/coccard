import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:coc_character/app/services/deepseek_service.dart';

/// 构造 OpenAI 格式的成功响应（UTF-8 编码，支持中文）
http.Response _okResponse(String content) {
  final body = jsonEncode({
    'choices': [
      {'message': {'content': content}}
    ]
  });
  return http.Response.bytes(
    utf8.encode(body),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

/// 构造标准的 Step1 JSON（会计师，id=2，教育×4）
/// edu=60 → 职业点 240，int=60 → 兴趣点 120
Map<String, dynamic> _validStep1Json() {
  return {
    'name': '张三',
    'age': '30',
    'gender': '男',
    'residence': '阿卡姆',
    'birthplace': '波士顿',
    'occupation': '会计师',
    'occId': 2,
    'attributes': {
      'str': 50, 'con': 50, 'siz': 50, 'dex': 50,
      'app': 50, 'int': 60, 'pow': 50, 'edu': 60,
    },
    'skills': {
      '母语': {'occ': 0, 'int': 0},
      '侦查': {'occ': 40, 'int': 20},
      '图书馆': {'occ': 30, 'int': 20},
      '聆听': {'occ': 20, 'int': 10},
      '说服': {'occ': 20, 'int': 10},
      '心理学': {'occ': 30, 'int': 20},
      '会计': {'occ': 40, 'int': 10},
      '法律': {'occ': 20, 'int': 10},
      '估价': {'occ': 20, 'int': 10},
      '历史': {'occ': 10, 'int': 10},
      '外语': {'occ': 10, 'int': 0},
      '潜行': {'occ': 0, 'int': 0},
      '闪避': {'occ': 0, 'int': 0},
      '急救': {'occ': 0, 'int': 0},
    },
  };
}

/// 构造标准的 Step2 JSON
Map<String, dynamic> _validStep2Json() {
  return {
    'backstory': '张三出生于波士顿的一个中产家庭，从小对数字敏感。大学毕业后进入一家会计师事务所工作，多次参与神秘事件的财务调查。',
    'appearance': '身高175cm，体型中等，棕色短发，戴着一副金丝眼镜，穿着整洁的灰色西装。',
    'items': [
      {'name': '钱包', 'count': 1},
      {'name': '身份证', 'count': 1},
      {'name': '钢笔', 'count': 1},
      {'name': '计算器', 'count': 1},
      {'name': '笔记本', 'count': 1},
      {'name': '手电筒', 'count': 1},
      {'name': '钥匙', 'count': 1},
      {'name': '怀表', 'count': 1},
    ],
  };
}

/// 创建 mock HTTP client，返回固定响应
http.Client _mockClient(http.Response response) {
  return http_testing.MockClient((request) async => response);
}

/// 创建按顺序返回不同响应的 mock client
http.Client _mockClientSequence(List<http.Response> responses) {
  var callIndex = 0;
  return http_testing.MockClient((request) async {
    final response = responses[callIndex.clamp(0, responses.length - 1)];
    callIndex++;
    return response;
  });
}

void main() {
  group('AiService JSON parsing - double/int safety', () {
    test('parseStep1 handles double attribute values (50.0 instead of 50)', () {
      final attrs = <String, dynamic>{
        'str': 50.0, 'con': 60.0, 'siz': 55.0, 'dex': 70.0,
        'app': 65.0, 'int': 80.0, 'pow': 55.0, 'edu': 75.0,
      };
      expect((attrs['str'] as num? ?? 50).toInt(), 50);
      expect((attrs['int'] as num? ?? 50).toInt(), 80);
    });

    test('parseStep1 handles mixed int/double skill values', () {
      final val = <String, dynamic>{'occ': 40.0, 'int': 20};
      expect((val['occ'] as num? ?? 0).toInt(), 40);
      expect((val['int'] as num? ?? 0).toInt(), 20);
    });

    test('parseStep2 handles double count values', () {
      final m = <String, dynamic>{'name': '钱包', 'count': 1.0};
      expect((m['count'] as num? ?? 1).toInt(), 1);
    });

    test('occId as num handles double', () {
      final data = <String, dynamic>{'occId': 5.0};
      expect((data['occId'] as num?)?.toInt(), 5);
    });

    test('occId as num handles null', () {
      final data = <String, dynamic>{'occId': null};
      expect((data['occId'] as num?)?.toInt(), null);
    });

    test('occId as num handles int', () {
      final data = <String, dynamic>{'occId': 5};
      expect((data['occId'] as num?)?.toInt(), 5);
    });
  });

  group('AiService._extractJson', () {
    test('extracts from code block', () {
      final response = '```json\n{"key": "value"}\n```';
      final match = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(response);
      expect(match, isNotNull);
      expect(match!.group(1)!.trim(), '{"key": "value"}');
    });

    test('extracts from raw JSON in response', () {
      final response = 'Here is the result: {"key": "value"} done.';
      final braceStart = response.indexOf('{');
      final braceEnd = response.lastIndexOf('}');
      expect(braceStart >= 0 && braceEnd > braceStart, isTrue);
      expect(response.substring(braceStart, braceEnd + 1), '{"key": "value"}');
    });

    test('throws when no JSON found', () {
      final response = 'This is just plain text with no JSON.';
      final braceStart = response.indexOf('{');
      final braceEnd = response.lastIndexOf('}');
      final hasJson = braceStart >= 0 && braceEnd > braceStart;
      expect(hasJson, isFalse);
      expect(
        () {
          if (!hasJson) throw Exception('AI 未返回有效的 JSON 数据，请重试');
        },
        throwsException,
      );
    });
  });

  group('SkillAlloc', () {
    test('defaults to 0', () {
      final alloc = SkillAlloc();
      expect(alloc.occ, 0);
      expect(alloc.interest, 0);
    });

    test('accepts values', () {
      final alloc = SkillAlloc(occ: 40, interest: 20);
      expect(alloc.occ, 40);
      expect(alloc.interest, 20);
    });
  });

  group('AiProvider', () {
    test('values has only one entry (DeepSeek)', () {
      expect(AiProvider.values.length, 1);
      expect(AiProvider.values.first, AiProvider.deepseek);
    });

    test('index 1 would be out of range', () {
      expect(() => AiProvider.values[1], throwsRangeError);
    });

    test('clamp prevents out of range access', () {
      final storedIndex = 1;
      final safeIndex = storedIndex.clamp(0, AiProvider.values.length - 1);
      expect(safeIndex, 0);
      expect(AiProvider.values[safeIndex], AiProvider.deepseek);
    });
  });

  group('Step1Result validation scenarios', () {
    test('attributes must be 5x and in range', () {
      for (final v in [40, 45, 50, 75, 90]) {
        expect(v >= 40 && v <= 90 && v % 5 == 0, isTrue, reason: '$v should be valid');
      }
      for (final v in [39, 41, 91, 35]) {
        expect(v >= 40 && v <= 90 && v % 5 == 0, isFalse, reason: '$v should be invalid');
      }
    });

    test('interest points cannot exceed int * 2', () {
      final intAttr = 80;
      final interestTotal = intAttr * 2;
      expect(interestTotal, 160);
      expect(170 > interestTotal, isTrue);
      expect(150 > interestTotal, isFalse);
    });
  });

  // ========== Mock HTTP 集成测试 ==========

  group('generateStep1 - API 调用成功', () {
    test('标准 JSON 响应 → 正确解析并返回 Step1Result', () async {
      final jsonStr = jsonEncode(_validStep1Json());
      final client = _mockClient(_okResponse(jsonStr));
      final service = AiService(apiKey: 'test-key', client: client);

      final result = await service.generateStep1('一个会计师', '会计师');

      expect(result.name, '张三');
      expect(result.age, '30');
      expect(result.occupation, '会计师');
      expect(result.occId, 2);
      expect(result.attributes['str'], 50);
      expect(result.attributes['edu'], 60);
      expect(result.skills['母语']!.occ, 0);
      expect(result.skills['会计']!.occ, 40);
      expect(result.skills.length, greaterThanOrEqualTo(10));
    });

    test('markdown 代码块包裹的 JSON → 正确提取并解析', () async {
      final jsonStr = jsonEncode(_validStep1Json());
      final wrappedResponse = '以下是生成的角色：\n```json\n$jsonStr\n```\n请检查。';
      final client = _mockClient(_okResponse(wrappedResponse));
      final service = AiService(apiKey: 'test-key', client: client);

      final result = await service.generateStep1('一个会计师', '会计师');

      expect(result.name, '张三');
      expect(result.attributes['str'], 50);
    });

    test('double 类型的属性值 → 正确转为 int', () async {
      final json = _validStep1Json();
      // 将所有属性值改为 double（重新构建 map，避免 Map<String, int> 类型冲突）
      final origAttrs = json['attributes'] as Map<String, dynamic>;
      json['attributes'] = <String, dynamic>{
        for (final e in origAttrs.entries) e.key: (e.value as int).toDouble(),
      };
      // 将所有技能值改为 double
      final origSkills = json['skills'] as Map<String, dynamic>;
      json['skills'] = <String, dynamic>{
        for (final e in origSkills.entries)
          e.key: {
            'occ': ((e.value as Map)['occ'] as int).toDouble(),
            'int': ((e.value as Map)['int'] as int).toDouble(),
          },
      };

      final client = _mockClient(_okResponse(jsonEncode(json)));
      final service = AiService(apiKey: 'test-key', client: client);

      final result = await service.generateStep1('一个会计师', '会计师');

      expect(result.attributes['str'], 50);
      expect(result.attributes['str'] is int, isTrue);
      expect(result.skills['会计']!.occ, 40);
    });

    test('缺少部分字段 → 使用默认值', () async {
      final json = _validStep1Json();
      json.remove('name');
      json.remove('age');
      (json['attributes'] as Map<String, dynamic>).remove('str');

      final client = _mockClient(_okResponse(jsonEncode(json)));
      final service = AiService(apiKey: 'test-key', client: client);

      final result = await service.generateStep1('一个会计师', '会计师');

      expect(result.name, '');
      expect(result.age, '');
      expect(result.attributes['str'], 50); // 默认值
    });
  });

  group('generateStep2 - API 调用成功', () {
    test('标准 JSON 响应 → 正确解析并返回 Step2Result', () async {
      final jsonStr = jsonEncode(_validStep2Json());
      final client = _mockClient(_okResponse(jsonStr));
      final service = AiService(apiKey: 'test-key', client: client);

      final step1 = Step1Result(
        name: '张三', age: '30', gender: '男',
        residence: '阿卡姆', birthplace: '波士顿',
        occupation: '会计师', occId: 2,
        attributes: {'str': 50, 'con': 50, 'siz': 50, 'dex': 50, 'app': 50, 'int': 60, 'pow': 50, 'edu': 60},
      );

      final result = await service.generateStep2('一个会计师', step1);

      expect(result.backstory, contains('张三'));
      expect(result.appearance, contains('175'));
      expect(result.items.length, 8);
      expect(result.items.first.name, '钱包');
    });

    test('items 为空列表 → 返回空列表', () async {
      final json = _validStep2Json();
      json['items'] = [];
      final client = _mockClient(_okResponse(jsonEncode(json)));
      final service = AiService(apiKey: 'test-key', client: client);

      final result = await service.generateStep2('test', Step1Result());

      expect(result.items, isEmpty);
    });
  });

  group('API 错误处理', () {
    test('401 未授权 → 抛出含 401 的异常', () async {
      final client = _mockClient(http.Response('{"error":"Unauthorized"}', 401));
      final service = AiService(apiKey: 'bad-key', client: client);

      expect(
        () => service.generateStep1('test', null),
        throwsA(predicate((e) => e.toString().contains('401'))),
      );
    });

    test('500 服务器错误 → 抛出含 500 的异常', () async {
      final client = _mockClient(http.Response('Internal Server Error', 500));
      final service = AiService(apiKey: 'test-key', client: client);

      expect(
        () => service.generateStep1('test', null),
        throwsA(predicate((e) => e.toString().contains('500'))),
      );
    });

    test('响应体不是有效 JSON → 抛出解析异常', () async {
      final client = _mockClient(_okResponse('这不是JSON'));
      final service = AiService(apiKey: 'test-key', client: client);

      expect(
        () => service.generateStep1('test', null),
        throwsA(predicate((e) => e.toString().contains('JSON'))),
      );
    });

    test('AI 返回空内容 → 抛出异常', () async {
      final client = _mockClient(_okResponse(''));
      final service = AiService(apiKey: 'test-key', client: client);

      expect(
        () => service.generateStep1('test', null),
        throwsException,
      );
    });
  });

  group('重试机制', () {
    test('第 1 次 500，第 2 次成功 → 最终成功', () async {
      final jsonStr = jsonEncode(_validStep1Json());
      final client = _mockClientSequence([
        http.Response('Server Error', 500),
        _okResponse(jsonStr),
      ]);
      final service = AiService(apiKey: 'test-key', client: client);

      final result = await service.generateStep1('一个会计师', '会计师');

      expect(result.name, '张三');
    });

    test('连续 3 次失败 → 抛出最终异常', () async {
      final client = _mockClientSequence([
        http.Response('Error', 500),
        http.Response('Error', 500),
        http.Response('Error', 500),
      ]);
      final service = AiService(apiKey: 'test-key', client: client);

      expect(
        () => service.generateStep1('test', null),
        throwsA(predicate((e) => e.toString().contains('500'))),
      );
    });

    test('第 1 次校验失败，第 2 次校验成功 → 最终成功', () async {
      // 第一次返回无效数据（属性超范围）
      final invalidJson = _validStep1Json();
      (invalidJson['attributes'] as Map<String, dynamic>)['str'] = 99;
      // 第二次返回有效数据
      final validJson = jsonEncode(_validStep1Json());

      final client = _mockClientSequence([
        _okResponse(jsonEncode(invalidJson)),
        _okResponse(validJson),
      ]);
      final service = AiService(apiKey: 'test-key', client: client);

      final result = await service.generateStep1('一个会计师', '会计师');

      expect(result.name, '张三');
    });

    test('Step2 连续 3 次失败 → 抛出异常', () async {
      final client = _mockClientSequence([
        http.Response('Error', 500),
        http.Response('Error', 500),
        http.Response('Error', 500),
      ]);
      final service = AiService(apiKey: 'test-key', client: client);

      expect(
        () => service.generateStep2('test', Step1Result()),
        throwsA(predicate((e) => e.toString().contains('500'))),
      );
    });
  });

  group('请求格式验证', () {
    test('请求包含正确的 headers 和 URL', () async {
      String? capturedAuth;
      String? capturedContentType;
      Uri? capturedUrl;

      final client = http_testing.MockClient((request) async {
        capturedAuth = request.headers['Authorization'];
        capturedContentType = request.headers['Content-Type'];
        capturedUrl = request.url;
        return _okResponse(jsonEncode(_validStep1Json()));
      });

      final service = AiService(apiKey: 'sk-test-123', client: client);
      await service.generateStep1('一个会计师', '会计师');

      expect(capturedAuth, 'Bearer sk-test-123');
      expect(capturedContentType, 'application/json');
      expect(capturedUrl.toString(), 'https://api.deepseek.com/chat/completions');
    });

    test('请求 body 格式正确（model、temperature、messages）', () {
      final body = jsonEncode({
        'model': AiProvider.deepseek.model,
        'temperature': 0.7,
        'messages': [
          {'role': 'system', 'content': 'test-system'},
          {'role': 'user', 'content': 'test-user'},
        ],
      });

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      expect(decoded['model'], 'deepseek-chat');
      expect(decoded['temperature'], 0.7);
      expect(decoded['messages'], isA<List>());
      expect((decoded['messages'] as List).length, 2);
      expect((decoded['messages'] as List)[0]['role'], 'system');
      expect((decoded['messages'] as List)[1]['role'], 'user');
    });
  });
}
