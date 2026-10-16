import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/store/ui_state.dart';
import 'package:paisa/ui/screens/home/home_screen.dart';

import '../app_harness.dart';

ScrollPosition carouselPosition(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(of: find.byKey(const Key('account-carousel')), matching: find.byType(Scrollable)),
    )
    .position;

void main() {
  testWidgets('hero is the month plan: save, repay, budgets, what you have and what is free to spend', (tester) async {
    await pumpPaisa(tester);
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('OCTOBER PLAN'), findsOneWidget);
    expect(find.text('17 days left'), findsOneWidget);
    for (final row in ['Save', 'Repay loans', 'Budgets', 'You have', 'Net worth']) {
      expect(find.text(row), findsOneWidget, reason: row);
    }
    expect(find.text('FREE TO SPEND'), findsOneWidget);
    expect(find.text('after saving and EMIs'), findsOneWidget);
    expect(find.text('NPR 1,84,020'), findsOneWidget, reason: 'you have');
    expect(find.text('NPR 10,87,327'), findsOneWidget, reason: 'net worth');
    expect(find.text('AVAILABLE TO SPEND'), findsNothing);
    for (final label in ['Income', 'Expense', 'Loans']) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
  });

  testWidgets('account cards list non-locked accounts, first one first', (tester) async {
    await pumpPaisa(tester);
    expect(find.text('Nabil ••4821'), findsOneWidget);
    expect(find.text('Bank account'), findsWidgets);
    expect(find.text('FD ••0915'), findsNothing, reason: 'locked accounts are not on Home');
  });

  testWidgets('month card and loans card show this month and what is owed', (tester) async {
    await pumpPaisa(tester);
    expect(find.text('October so far'), findsOneWidget);
    expect(find.text('NPR 26,240'), findsOneWidget);
    expect(find.text('NPR 53,674'), findsOneWidget);
    expect(find.text('Deficit '), findsOneWidget);
    expect(find.text('Loans remaining'), findsOneWidget);
    expect(find.text('NPR 4,44,253'), findsOneWidget);
    expect(find.text('37% repaid'), findsOneWidget);
    expect(find.textContaining('Plan how to pay it off'), findsOneWidget);
  });

  test('debtFreeLabel: none without loans or when a loan is never repaid', () {
    expect(debtFreeLabel(const [], '2026-10-14'), isNull);
    const stuck = Loan(
      id: 'x',
      loanTypeId: 'personal',
      name: 'x',
      lender: 'y',
      principal: 100000000,
      outstanding: 100000000,
      ratePct: 24,
      method: InterestMethod.reducing,
      installment: 100,
      frequency: LoanFrequency.monthly,
    );
    expect(debtFreeLabel(const [stuck], '2026-10-14'), isNull);
    const easy = Loan(
      id: 'e',
      loanTypeId: 'family',
      name: 'e',
      lender: 'k',
      principal: 1000000,
      outstanding: 1000000,
      ratePct: 0,
      method: InterestMethod.none,
      installment: 500000,
      frequency: LoanFrequency.monthly,
    );
    expect(debtFreeLabel(const [easy], '2026-10-14'), 'Debt-free Dec 2026');
  });

  test('greetingFor follows the clock', () {
    expect(greetingFor(DateTime(2026, 10, 14, 9)), 'Good morning');
    expect(greetingFor(DateTime(2026, 10, 14, 13)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 10, 14, 19)), 'Good evening');
  });

  testWidgets('recent shows the last three transactions; tapping opens the sheet', (tester) async {
    await pumpPaisa(tester);
    await scrollPageTo(tester, find.text('Nepal Oil — petrol'));
    expect(find.text('WorldLink internet'), findsOneWidget);
    expect(find.text('NIC Asia interest credit'), findsOneWidget);
    expect(find.text('Freelance — product audit'), findsNothing);
    await tester.tap(find.text('Nepal Oil — petrol'));
    await tester.pumpAndSettle();
    expect(find.text('Entered manually'), findsOneWidget);
  });

  testWidgets('review focus: hide balances masks every amount on Home', (tester) async {
    await pumpPaisa(tester);
    await tester.tap(find.bySemanticsLabel('Hide balances'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Show balances'), findsOneWidget);
    expect(find.textContaining(RegExp(r'\d{1,3},\d{3}')), findsNothing);
    expect(find.text('••••••'), findsOneWidget);
  });

  testWidgets('quick action Expense opens Add expense; Cancel returns Home', (tester) async {
    await pumpPaisa(tester);
    await tester.tap(find.bySemanticsLabel('Expense'));
    await tester.pumpAndSettle();
    expect(find.text('Add expense'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('FREE TO SPEND'), findsOneWidget);
  });

  testWidgets('the SMS bar appears when messages wait for review', (tester) async {
    await pumpPaisa(tester, overrides: [inboxPendingCountProvider.overrideWithValue(7)]);
    expect(find.text('7 SMS to review'), findsOneWidget);
    expect(find.text('Nothing is saved until you confirm'), findsOneWidget);
  });

  group('acceptance 15: account cards scroll', () {
    testWidgets('by touch swipe', (tester) async {
      await pumpPaisa(tester);
      await scrollPageTo(tester, find.byKey(const Key('account-carousel')));
      await tester.drag(find.byKey(const Key('account-carousel')), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(carouselPosition(tester).pixels, greaterThan(0));
    });

    testWidgets('by mouse drag', (tester) async {
      await pumpPaisa(tester);
      await scrollPageTo(tester, find.byKey(const Key('account-carousel')));
      await tester.drag(
        find.byKey(const Key('account-carousel')),
        const Offset(-300, 0),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(carouselPosition(tester).pixels, greaterThan(0));
    });

    testWidgets('by mouse wheel', (tester) async {
      await pumpPaisa(tester);
      await scrollPageTo(tester, find.byKey(const Key('account-carousel')));
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      pointer.hover(tester.getCenter(find.byKey(const Key('account-carousel'))));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 250)));
      await tester.pump();
      expect(carouselPosition(tester).pixels, 250);
    });

    testWidgets('the last card opens Add account', (tester) async {
      await pumpPaisa(tester);
      await scrollPageTo(tester, find.byKey(const Key('account-carousel')));
      await tester.scrollUntilVisible(
        find.text('Add eSewa, Khalti or bank'),
        300,
        scrollable: find.descendant(of: find.byKey(const Key('account-carousel')), matching: find.byType(Scrollable)),
      );
      await tester.tap(find.text('Add eSewa, Khalti or bank'));
      await tester.pumpAndSettle();
      expect(find.text('Quick pick'), findsOneWidget);
    });
  });

  testWidgets('a card opens its account page', (tester) async {
    await pumpPaisa(tester);
    await scrollPageTo(tester, find.byKey(const Key('account-carousel')));
    await tester.tap(find.text('Nabil ••4821'));
    await tester.pumpAndSettle();
    expect(find.text('Nabil Bank — Salary'), findsOneWidget);
    expect(find.text('Current balance'), findsOneWidget);
  });

  testWidgets('review focus: a 320 px wide screen lays out without overflow', (tester) async {
    await pumpPaisa(tester, size: const Size(320, 640));
    await scrollPageTo(tester, find.text('Recent'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('review fix: card amounts of a lakh or more show every digit with the real font', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('SpaceGrotesk')..addFont(rootBundle.load('assets/fonts/SpaceGrotesk-Variable.ttf'));
      await loader.load();
    });
    await pumpPaisa(tester);
    final amount = find.text('NPR 3,85,000');
    await tester.scrollUntilVisible(
      amount,
      200,
      scrollable: find.descendant(of: find.byKey(const Key('account-carousel')), matching: find.byType(Scrollable)),
    );
    final paragraph = tester.renderObject<RenderParagraph>(amount);
    final boxes = paragraph.getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 'NPR 3,85,000'.length));
    expect(boxes.map((b) => b.top).toSet(), hasLength(1), reason: 'digits must not wrap onto a hidden second line');
    expect(paragraph.didExceedMaxLines, isFalse);
  });
}
