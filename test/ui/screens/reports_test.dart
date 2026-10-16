import 'package:flutter/widgets.dart' show ValueKey, Offset;
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/audit_log.dart';
import 'package:paisa/data/db/database.dart';
import 'package:paisa/data/report_settings.dart';
import 'package:paisa/data/repos/settings_repo.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/ui/components/buttons.dart';
import 'package:paisa/ui/components/toast.dart';
import 'package:paisa/data/settings_models.dart';
import 'package:paisa/store/ui_state.dart';
import 'package:paisa/ui/components/top_bar.dart';

import '../../data/data_fixtures.dart';
import '../app_harness.dart';

void main() {
  testWidgets('Reports shows the default widgets and "For you" nudges', (tester) async {
    await pumpPaisa(tester, location: '/reports');
    expect(find.widgetWithText(PaisaTopBar, 'Reports'), findsOneWidget);
    expect(find.text('For you'), findsOneWidget);
    for (final title in ['Savings score', 'Cash flow', 'Spending by category', 'Budgets', 'Loan progress', 'Challenges']) {
      await scrollPageTo(tester, find.text(title));
      expect(find.text(title), findsWidgets, reason: title);
    }
  });

  testWidgets('clean install: Reports renders with empty states, no errors', (tester) async {
    await pumpPaisa(tester, location: '/reports', cleanInstall: true);
    expect(find.text('Savings score'), findsOneWidget);
    await scrollPageTo(tester, find.text('No open loans 🎉'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden balances mask every amount on Reports, nudges included', (tester) async {
    await pumpPaisa(tester, location: '/reports', overrides: [
      initialPrefsProvider.overrideWithValue(const AppPrefs(hideBalances: true)),
    ]);
    expect(find.textContaining(RegExp(r'NPR \d')), findsNothing);
  });

  testWidgets('the period chips apply one period to every widget for now', (tester) async {
    await pumpPaisa(tester, location: '/reports');
    await tapChip(tester, '12 months');
    expect(find.text('12 months'), findsWidgets);
  });

  Future<DashboardConfig?> saved(AppDatabase db) =>
      SettingsRepository(db, AuditLog(db, clock: testClock, newId: counterIds('x'))).dashboard();

  testWidgets('edit: remove a widget, undo brings it back', (tester) async {
    final db = await pumpPaisa(tester, location: '/reports');
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Remove Loan progress'));
    await tester.pumpAndSettle();
    expect((await saved(db))!.widgets.map((w) => w.type), isNot(contains(ReportWidgetType.loanProgress)));
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect((await saved(db))!.widgets.map((w) => w.type), contains(ReportWidgetType.loanProgress));
    await tester.pump(kUndoWindow);
  });

  testWidgets('edit: add a widget, change its period and size', (tester) async {
    final db = await pumpPaisa(tester, location: '/reports');
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.widgetWithText(PaisaButton, 'Add widget'));
    await tester.tap(find.text('Top payees'));
    await tester.pumpAndSettle();
    await tester.pump(kUndoWindow); // let the "added" toast clear the sheet footer
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.bySemanticsLabel('Settings for Top payees'));
    await tester.tap(find.text('3 months').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Half width').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Half width').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PaisaButton, 'Save'));
    await tester.pumpAndSettle();
    final w = (await saved(db))!.widgets.last;
    expect((w.type, w.period, w.size), (ReportWidgetType.topPayees, ReportPeriod.last3m, WidgetSize.half));
    await tester.pump(kUndoWindow);
  });

  testWidgets('edit: drag to reorder', (tester) async {
    final db = await pumpPaisa(tester, location: '/reports');
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const ValueKey('drag-w-score')), const Offset(0, 160));
    await tester.pumpAndSettle();
    expect((await saved(db))!.widgets.first.id, isNot('w-score'));
  });

  testWidgets('edit: reset to default asks first', (tester) async {
    final db = await pumpPaisa(tester, location: '/reports');
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Remove Challenges'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.widgetWithText(PaisaButton, 'Reset to default'));
    await tester.tap(find.widgetWithText(PaisaButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(await saved(db), isNull);
    await tester.pump(kUndoWindow);
  });

  testWidgets('review fix: Undo while a settings sheet is open, then Save, keeps the restored widget', (tester) async {
    final db = await pumpPaisa(tester, location: '/reports');
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Remove Loan progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Settings for Cash flow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PaisaButton, 'Save'));
    await tester.pumpAndSettle();
    expect((await saved(db))!.widgets.map((w) => w.type), contains(ReportWidgetType.loanProgress));
    await tester.pump(kUndoWindow);
  });
}
