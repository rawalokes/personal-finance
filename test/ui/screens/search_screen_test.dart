import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_harness.dart';

void main() {
  group('Search', () {
    testWidgets('lists everything until you type, then filters by text', (tester) async {
      await pumpPaisa(tester, location: '/activity');
      await tester.tap(find.bySemanticsLabel('Search and filter'));
      await tester.pumpAndSettle();
      expect(find.text('All 17 transactions'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'bhat-bhateni');
      await tester.pump();
      expect(find.text('1 result for “bhat-bhateni”'), findsOneWidget);
      expect(find.text('Bhat-Bhateni Supermarket'), findsOneWidget);
    });

    testWidgets('type chips combine with the text', (tester) async {
      await pumpPaisa(tester, location: '/search');
      await tester.enterText(find.byType(EditableText), 'nabil');
      await tester.pump();
      await tapChip(tester, 'Income');
      expect(find.text('2 results for “nabil”'), findsOneWidget);
    });

    testWidgets('no matches shows the empty state', (tester) async {
      await pumpPaisa(tester, location: '/search');
      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pump();
      expect(find.text('No matches'), findsOneWidget);
      expect(find.text('0 results for “zzz”'), findsOneWidget);
    });

    testWidgets('Back leaves search', (tester) async {
      await pumpPaisa(tester);
      await tester.tap(find.bySemanticsLabel('Search transactions'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('FREE TO SPEND'), findsOneWidget);
    });
  });
}
