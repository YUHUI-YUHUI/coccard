import 'package:flutter_test/flutter_test.dart';
import 'package:coc_character/app/data/rule_knowledge.dart';

void main() {
  group('searchRuleKnowledge', () {
    test('空查询返回全部条目（受 limit 限制）', () {
      final hits = searchRuleKnowledge('', limit: 100);
      expect(hits.length, ruleKnowledgeEntries.length);
      expect(hits.length, greaterThanOrEqualTo(10));
    });

    test('关键词命中对应条目且排序靠前', () {
      final hits = searchRuleKnowledge('奖励骰');
      expect(hits, isNotEmpty);
      expect(hits.first.title, '奖励骰与惩罚骰');
    });

    test('标签词可命中', () {
      final hits = searchRuleKnowledge('大失败');
      expect(hits, isNotEmpty);
      expect(hits.any((e) => e.title == 'D100 检定与成功等级'), isTrue);
    });

    test('带疑问后缀的整句可命中关键词条目', () {
      final hits = searchRuleKnowledge('奖励骰怎么用？');
      expect(hits, isNotEmpty);
      expect(hits.first.title, '奖励骰与惩罚骰');
    });

    test('连接词切分可命中多个关键词', () {
      final hits = searchRuleKnowledge('大成功和大失败怎么判定？');
      expect(hits, isNotEmpty);
      expect(hits.any((e) => e.title == 'D100 检定与成功等级'), isTrue);
    });

    test('无匹配返回空列表', () {
      expect(searchRuleKnowledge('不存在的规则zzz'), isEmpty);
    });

    test('category 过滤生效', () {
      final hits = searchRuleKnowledge('', category: '理智', limit: 100);
      expect(hits, isNotEmpty);
      expect(hits.every((e) => e.category == '理智'), isTrue);
    });
  });

  group('RuleKnowledgeEntry', () {
    test('matches 支持关键词与分类过滤', () {
      final entry = ruleKnowledgeEntries.first;
      expect(entry.matches('成功等级', '全部'), isTrue);
      expect(entry.matches('成功等级', '检定'), isTrue);
      expect(entry.matches('成功等级', '战斗'), isFalse);
      expect(entry.matches('完全无关', '全部'), isFalse);
    });

    test('toContextString 包含标题与要点', () {
      final text = ruleKnowledgeEntries.first.toContextString();
      expect(text, contains('D100 检定与成功等级'));
      expect(text, contains('困难成功'));
    });
  });
}
