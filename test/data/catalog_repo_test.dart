import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/repos/catalog_repo.dart';
import 'package:paisa/finance/finance.dart';

import 'data_fixtures.dart';

void main() {
  test('addRecurring saves the rule; undo removes it', () async {
    final db = await ledgerDb();
    final repo = CatalogRepository(db, testAudit(db));
    const rule = RecurringRule(
      id: 'r9', name: 'WorldLink internet', kind: RecurringKind.expense, amount: 169500,
      categoryId: 'utilities', accountId: 'esewa', frequency: RecurringFrequency.monthly, nextDate: '2026-11-13',
    );
    final undo = await repo.addRecurring(rule);
    expect((await repo.watchRecurring().first).single.name, 'WorldLink internet');
    expect(await auditSummaries(db), ['Added recurring WorldLink internet · NPR 1,695']);
    await undo();
    expect(await repo.watchRecurring().first, isEmpty);
  });

  test('watchLoans lists loans', () async {
    final db = await ledgerDb();
    expect((await CatalogRepository(db, testAudit(db)).watchLoans().first).single.id, 'L3');
  });
}
