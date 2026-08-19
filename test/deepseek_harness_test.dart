import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:coc_character/app/services/deepseek_harness.dart';
import 'package:coc_character/app/services/deepseek_service.dart';

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

Map<String, dynamic> _step1Json() {
  return {
    'name': '李四',
    'age': '35',
    'gender': '女',
    'residence': '伦敦',
    'birthplace': '爱丁堡',
    'occupation': '记者',
    'occId': 260,
    'attributes': {
      'str': 50, 'con': 55, 'siz': 55, 'dex': 60,
      'app': 65, 'int': 70, 'pow': 50, 'edu': 75,
    },
    'skills': {
      '母语': {'occ': 0, 'int': 0},
      '侦查': {'occ': 40, 'int': 30},
      '图书馆': {'occ': 30, 'int': 20},
      '聆听': {'occ': 20, 'int': 10},
      '说服': {'occ': 30, 'int': 20},
      '心理学': {'occ': 20, 'int': 10},
      '会计': {'occ': 10, 'int': 10},
      '历史': {'occ': 10, 'int': 10},
      '潜行': {'occ': 0, 'int': 0},
      '急救': {'occ': 0, 'int': 0},
      '闪避': {'occ': 0, 'int': 0},
    },
  };
}

Map<String, dynamic> _step2Json() {
  return {
    'backstory': '李四出生于爱丁堡的一个记者家庭，成年后前往伦敦从事新闻行业，多次深入调查离奇事件。',
    'appearance': '身高168cm，栗色长发，穿着干练的风衣，随身携带相机与笔记本。',
    'items': [
      {'name': '相机', 'count': 1},
      {'name': '笔记本', 'count': 1},
      {'name': '记者证', 'count': 1},
    ],
    'cash': 120,
  };
}

DeepseekHarness _harnessWith(http.Client client) {
  return DeepseekHarness(
    ai: AiService(apiKey: 'sk-test', client: client),
  );
}

void main() {
  group('DeepseekHarness.detectMode', () {
    late DeepseekHarness harness;
    setUp(() {
      harness = _harnessWith(
        http_testing.MockClient((_) async => _okResponse('ok')),
      );
    });

    test('建卡关键词', () {
      expect(harness.detectMode('帮我生成一张角色卡'), HarnessMode.characterCreate);
      expect(harness.detectMode('创建一个大学教授角色'), HarnessMode.characterCreate);
    });

    test('场景关键词', () {
      expect(
        harness.detectMode('场景：他们在古宅的地下室发现了诡异的符号'),
        HarnessMode.sceneAction,
      );
      expect(harness.detectMode('接下来该怎么办'), HarnessMode.sceneAction);
    });

    test('规则关键词', () {
      expect(harness.detectMode('奖励骰和惩罚骰怎么判定？'), HarnessMode.research);
      expect(harness.detectMode('临时疯狂是什么规则'), HarnessMode.research);
    });

    test('其他内容走自由对话', () {
      expect(harness.detectMode('今天天气怎么样'), HarnessMode.chat);
    });
  });

  group('DeepseekHarness.run', () {
    test('research 模式检索本地资料并带上上下文', () async {
      late String requestBody;
      final harness = _harnessWith(
        http_testing.MockClient((request) async {
          requestBody = request.body;
          return _okResponse('奖励骰取更有利的十位。');
        }),
      );

      final result = await harness.run(
        input: '奖励骰怎么用？',
        mode: HarnessMode.research,
      );

      expect(result.mode, HarnessMode.research);
      expect(result.steps, hasLength(1));
      expect(result.steps.first.title, '规则资料检索');
      expect(result.referenceHits, isNotEmpty);
      expect(result.referenceHits.first.title, '奖励骰与惩罚骰');
      expect(result.answer, contains('奖励骰取更有利的十位'));
      expect(requestBody, contains('奖励骰与惩罚骰'));
    });

    test('research 模式无命中时仍可回答', () async {
      final harness = _harnessWith(
        http_testing.MockClient((_) async => _okResponse('通用回答')),
      );
      final result = await harness.run(
        input: '完全无关的问题zzz',
        mode: HarnessMode.research,
      );
      expect(result.steps.first.title, '规则资料检索（无命中）');
      expect(result.answer, '通用回答');
    });

    test('sceneAction 模式生成行动建议', () async {
      late String requestBody;
      final harness = _harnessWith(
        http_testing.MockClient((request) async {
          requestBody = request.body;
          return _okResponse('## 场景要点\n气氛紧张');
        }),
      );

      final result = await harness.run(
        input: '调查员走进废弃疯人院，灯突然熄灭…',
        mode: HarnessMode.sceneAction,
      );

      expect(result.mode, HarnessMode.sceneAction);
      expect(result.steps.first.title, '场景行动生成');
      expect(result.answer, contains('气氛紧张'));
      expect(requestBody, contains('场景描述'));
      expect(requestBody, contains('废弃疯人院'));
    });

    test('characterCreate 模式复用两步建卡并返回结构化结果', () async {
      final harness = _harnessWith(
        http_testing.MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final messages = body['messages'] as List<dynamic>;
          final system = messages
              .whereType<Map<String, dynamic>>()
              .firstWhere((m) => m['role'] == 'system')['content'] as String;
          return _okResponse(system.contains('背景故事') ? jsonEncode(_step2Json()) : jsonEncode(_step1Json()));
        }),
      );

      final result = await harness.run(
        input: '一名来自伦敦的记者',
        mode: HarnessMode.characterCreate,
      );

      expect(result.steps, hasLength(2));
      expect(result.step1, isNotNull);
      expect(result.step2, isNotNull);
      expect(result.step1!.name, '李四');
      expect(result.step1!.occupation, '记者');
      expect(result.step2!.cash, 120);
      expect(result.answer, contains('李四'));
    });

    test('chat 模式走自由对话', () async {
      final harness = _harnessWith(
        http_testing.MockClient((_) async => _okResponse('你好！')),
      );
      final result = await harness.run(
        input: '你好',
        mode: HarnessMode.chat,
      );
      expect(result.steps.first.title, '自由对话');
      expect(result.answer, '你好！');
    });

    test('未指定模式时自动路由', () async {
      late String requestBody;
      final harness = _harnessWith(
        http_testing.MockClient((request) async {
          requestBody = request.body;
          return _okResponse('命中资料');
        }),
      );
      final result = await harness.run(input: '惩罚骰规则是什么？');
      expect(result.mode, HarnessMode.research);
      expect(requestBody, contains('惩罚骰'));
    });
  });
}
