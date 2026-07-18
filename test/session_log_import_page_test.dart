import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coc_character/app/pages/session_log_import_page.dart';

void main() {
  testWidgets('shows supported inputs on landing page', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SessionLogImportPage()));

    expect(find.text('把跑团记录变成聊天记录'), findsOneWidget);
    expect(find.byKey(const Key('pick_session_log_file')), findsOneWidget);
    expect(find.byKey(const Key('paste_session_log')), findsOneWidget);
    expect(find.text('DOCX'), findsOneWidget);
    expect(find.text('JSON'), findsOneWidget);
  });

  testWidgets('pasted log becomes chat bubbles and can select viewpoint',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SessionLogImportPage()));

    await tester.tap(find.byKey(const Key('paste_session_log')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('session_log_text_input')),
      '调查员：我来开门。\nKP：门后空无一人。',
    );
    await tester.tap(find.text('生成聊天'));
    await tester.pumpAndSettle();

    expect(find.text('调查员'), findsWidgets);
    expect(find.text('我来开门。'), findsOneWidget);
    expect(find.text('KP'), findsWidgets);
    expect(find.byKey(const Key('export_session_log')), findsOneWidget);
  });
}
