import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coc_character/app/pages/ai_harness_page.dart';

void main() {
  testWidgets('AI Harness 页面渲染模式选择与欢迎卡', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: AiHarnessPage()));
    await tester.pumpAndSettle();

    expect(find.text('DeepSeek Harness · AI 助手'), findsOneWidget);
    expect(find.text('自动判断'), findsAtLeastNWidgets(1));
    expect(find.text('资料问答'), findsAtLeastNWidgets(1));
    expect(find.text('场景行动'), findsAtLeastNWidgets(1));
    expect(find.text('AI 建卡'), findsAtLeastNWidgets(1));
  });

  testWidgets('发送消息后请求失败会提示生成失败', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: AiHarnessPage()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '奖励骰怎么判定？');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.textContaining('生成失败'), findsOneWidget);
  });
}
