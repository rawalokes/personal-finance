import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/mappers.dart';
import 'package:paisa/data/repos/settings_repo.dart';
import 'package:paisa/data/secret_store.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/store/app_lock.dart';
import 'package:paisa/ui/components/buttons.dart';
import 'package:paisa/ui/components/inputs.dart';
import 'package:paisa/ui/components/toast.dart';
import 'package:paisa/ui/screens/settings/data_actions.dart';

import '../../data/data_fixtures.dart';
import '../app_harness.dart';

class CapturedExport {
  String? name;
  String? content;
  Future<void> call(String fileName, String content, String mimeType) async {
    name = fileName;
    this.content = content;
  }
}

void main() {
  testWidgets('More lists financial setup, assistant, preferences and data', (tester) async {
    await pumpPaisa(tester, location: '/more');
    expect(find.text('Settings'), findsWidgets);
    for (final t in ['Income types', 'Salary & deductions', 'Tax rules', 'Expense categories', 'Loan types']) {
      expect(find.text(t), findsOneWidget);
    }
    await scrollPageTo(tester, find.text('Delete all data'));
    for (final t in ['AI assistant', 'Currency & date', 'Security & privacy', 'Export data', 'Audit history']) {
      expect(find.text(t), findsOneWidget);
    }
  });

  testWidgets('preferences: international grouping applies everywhere; BS calendar and light theme', (tester) async {
    await pumpPaisa(tester, location: '/settings/preferences');
    expect(find.text('Example: NPR 12,55,000'), findsOneWidget);
    await tester.tap(find.text('100,000'));
    await tester.pumpAndSettle();
    expect(find.text('Example: NPR 1,255,000'), findsOneWidget);
    await tester.tap(find.text('Bikram Sambat'));
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.text('Light'))).brightness, Brightness.light);
  });

  testWidgets('config list: add a bank, make it default, disable it', (tester) async {
    final db = await pumpPaisa(tester, location: '/settings/config/banks');
    expect(find.text('Banks & wallets'), findsOneWidget);
    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldLabelled('Name'), 'Laxmi Sunrise');
    await tester.enterText(fieldLabelled('Description'), 'Sender LSBL');
    await tester.tap(find.widgetWithText(PaisaButton, 'Add'));
    await tester.pumpAndSettle();
    await tester.pump(kUndoWindow); // let the "added" toast clear
    await scrollPageTo(tester, find.bySemanticsLabel('Disable Laxmi Sunrise'));
    await tester.tap(find.bySemanticsLabel('Disable Laxmi Sunrise'));
    await tester.pumpAndSettle();
    final row = (await db.select(db.configItems).get()).firstWhere((c) => c.name == 'Laxmi Sunrise');
    expect(row.active, isFalse);
  });

  testWidgets('categories: add one, duplicates are refused', (tester) async {
    await pumpPaisa(tester, location: '/settings/categories');
    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldLabelled('Name'), 'Groceries');
    await tester.tap(find.widgetWithText(PaisaButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('A category with this name already exists'), findsOneWidget);
    await tester.enterText(fieldLabelled('Name'), 'Pet care');
    await tester.tap(find.widgetWithText(PaisaButton, 'Save'));
    await tester.pumpAndSettle();
    await scrollPageTo(tester, find.text('Pet care'));
    expect(find.text('Pet care'), findsOneWidget);
    await tester.pump(kUndoWindow);
  });

  testWidgets('income types: disable Bonus; Add record opens Add income on that type', (tester) async {
    final db = await pumpPaisa(tester, location: '/settings/income-types');
    await tester.tap(find.bySemanticsLabel('Disable Bonus'));
    await tester.pumpAndSettle();
    expect((await (db.select(db.incomeTypes)..where((t) => t.id.equals('bonus'))).getSingle()).active, isFalse);
    await tester.tap(find.widgetWithText(PaisaButton, 'Add record').first);
    await tester.pumpAndSettle();
    expect(tester.widget<PaisaChip>(find.widgetWithText(PaisaChip, 'Monthly Salary')).selected, isTrue);
  });

  testWidgets('recurring rules: pause one', (tester) async {
    final db = await pumpPaisa(tester, location: '/settings/recurring');
    await tester.tap(find.bySemanticsLabel('Pause House rent'));
    await tester.pumpAndSettle();
    expect((await (db.select(db.recurringRules)..where((r) => r.id.equals('r1'))).getSingle()).active, isFalse);
  });

  testWidgets('salary simulator: gross 1,20,000 → take-home 92,789; employer SSF shown separately', (tester) async {
    await pumpPaisa(tester, location: '/settings/salary');
    expect(find.text('Sample defaults — verify for your fiscal year'), findsOneWidget);
    expect(find.text('NPR 92,789'), findsOneWidget);
    await scrollPageTo(tester, find.text('SSF — employer share'));
    expect(find.text('NPR 14,400'), findsWidgets);
  });

  testWidgets('salary: turning on provident fund lowers take-home and is saved', (tester) async {
    final db = await pumpPaisa(tester, location: '/settings/salary');
    await scrollPageTo(tester, find.bySemanticsLabel('Enable Provident fund'));
    await tester.tap(find.bySemanticsLabel('Enable Provident fund'));
    await tester.pumpAndSettle();
    final deds = await SettingsRepository(db, testAudit(db)).deductions();
    expect(deds.firstWhere((d) => d.id == 'pf').active, isTrue);
    final expected = computeSalary(
      grossMonthly: fromRupees(120000), basicPct: 60, deductions: deds, rules: sampleTaxRules(),
      taxCategory: 'individual', asOf: '2026-10-14',
    ).takeHome;
    expect(expected, lessThan(fromRupees(92789)));
    await tester.scrollUntilVisible(find.text('= Estimated take-home'), -200, scrollable: pageScrollable);
    await tester.pumpAndSettle();
    expect(find.text(const MoneyFormat().npr(expected)), findsOneWidget);
  });

  testWidgets('acceptance 9 (UI): overlapping brackets block saving; a valid edit saves', (tester) async {
    final db = await pumpPaisa(tester, location: '/settings/tax');
    expect(find.text('Nepal tax rules'), findsOneWidget);
    await scrollPageTo(tester, find.text('Slab 2 · Rate %'));
    await tester.enterText(fieldLabelled('Slab 2 · From'), '400000');
    await tester.pump();
    expect(find.textContaining('Overlaps the previous bracket'), findsOneWidget);
    await scrollAndTap(tester, find.widgetWithText(PaisaButton, 'Save tax rules'));
    expect(find.text('Fix the highlighted slabs before saving'), findsOneWidget);
    expect((await db.select(db.settings).get()).where((r) => r.key == SettingKey.taxRules), isEmpty);

    await tester.enterText(fieldLabelled('Slab 2 · From'), '500000');
    await tester.enterText(fieldLabelled('Slab 2 · Rate %'), '12');
    await tester.pump();
    await scrollAndTap(tester, find.widgetWithText(PaisaButton, 'Save tax rules'));
    expect(find.text('Tax rules saved · salary estimates updated'), findsOneWidget);
    final rules = await SettingsRepository(db, testAudit(db)).taxRules();
    expect(rules.categories['individual']![1].ratePct, 12);
    await tester.pump(kUndoWindow);
  });

  testWidgets('security: turning on the app lock asks for a PIN twice and stores only its hash', (tester) async {
    final store = MemorySecretStore();
    final db = await pumpPaisa(tester, location: '/settings/security', overrides: [
      secretStoreProvider.overrideWithValue(store),
    ]);
    await tester.tap(find.bySemanticsLabel('App lock'));
    await tester.pumpAndSettle();
    await tester.enterText(fieldLabelled('New PIN (4 digits)'), '4821');
    await tester.enterText(fieldLabelled('Repeat the PIN'), '4821');
    await tester.tap(find.widgetWithText(PaisaButton, 'Turn on app lock'));
    await tester.pumpAndSettle();
    expect(await PinService(store).verify('4821'), isTrue);
    expect((await SettingsRepository(db, testAudit(db)).security()).appLock, isTrue);
  });

  testWidgets('audit history lists changes with their source', (tester) async {
    await pumpPaisa(tester, location: '/settings/audit');
    expect(find.text('Added expense WorldLink internet · NPR 1,695'), findsOneWidget);
    expect(find.text('SMS'), findsOneWidget);
  });

  testWidgets('export JSON hands a backup to the share sheet', (tester) async {
    final captured = CapturedExport();
    await pumpPaisa(tester, location: '/more', overrides: [exporterProvider.overrideWithValue(captured.call)]);
    await scrollAndTap(tester, find.text('Export data'));
    await tester.tap(find.text('JSON backup'));
    await tester.tap(find.widgetWithText(PaisaButton, 'Export'));
    await tester.pumpAndSettle();
    expect(captured.name, 'paisa-backup-2026-10-14.json');
    expect(captured.content, contains('"accounts"'));
    await tester.pump(kUndoWindow);
  });

  testWidgets('delete all data needs the word DELETE, then leaves a clean install', (tester) async {
    final store = MemorySecretStore()..values['gemini_api_key'] = 'AIza-test';
    final db = await pumpPaisa(tester, location: '/more', overrides: [secretStoreProvider.overrideWithValue(store)]);
    await scrollAndTap(tester, find.text('Delete all data'));
    final button = find.widgetWithText(PaisaButton, 'Delete everything');
    expect(tester.widget<PaisaButton>(button).onPressed, isNull);
    await tester.enterText(fieldLabelled('Type DELETE to confirm'), 'DELETE');
    await tester.pump();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(await db.select(db.accounts).get(), isEmpty);
    expect(store.values, isEmpty, reason: 'AI key and PIN removed too');
    expect((await db.select(db.expenseCategories).get()).map(categoryFromRow).where((c) => c.monthlyBudget != null), isEmpty);
  });
}
