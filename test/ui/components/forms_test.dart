import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/data/undo.dart';
import 'package:paisa/finance/finance.dart';
import 'package:paisa/store/ui_state.dart';
import 'package:paisa/ui/components/layout.dart';
import 'package:paisa/ui/components/text_field.dart';
import 'package:paisa/ui/components/toast.dart';
import 'package:paisa/ui/components/tone.dart';
import 'package:paisa/ui/feedback.dart';
import 'package:paisa/ui/icons/paisa_icons.dart';
import 'package:paisa/ui/txn/transaction_tile.dart';
import 'package:paisa/ui/theme.dart';
import 'package:paisa/ui/tokens.dart';
import 'package:paisa/ui/txn/txn_presentation.dart';

import '../helpers.dart';

void main() {
  testWidgets('PaisaTextField shows its label, takes input and shows an error', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? changed;
    await tester.pumpWidget(wrap(PaisaTextField(
      label: 'Amount',
      controller: controller,
      big: true,
      hint: '0',
      errorText: 'Enter an amount greater than zero',
      onChanged: (v) => changed = v,
    )));
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Enter an amount greater than zero'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '1,500');
    expect(controller.text, '1,500');
    expect(changed, '1,500');
    expect(find.bySemanticsLabel(RegExp('^Amount')), findsOneWidget);
  });

  testWidgets('PaisaTextField shows the helper only when there is no error', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(wrap(PaisaTextField(label: 'Last 4 digits', controller: controller, helper: 'Never store the full number.')));
    expect(find.text('Never store the full number.'), findsOneWidget);
  });

  testWidgets('DateField shows the date and returns the picked one', (tester) async {
    IsoDate? picked;
    await tester.pumpWidget(wrap(DateField(label: 'Date', value: '2026-10-14', onChanged: (d) => picked = d)));
    expect(find.text('14 Oct 2026'), findsOneWidget);
    await tester.tap(find.text('14 Oct 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('12'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(picked, '2026-10-12');
  });

  testWidgets('KeyValueCard lays out label/value rows', (tester) async {
    await tester.pumpWidget(wrap(const KeyValueCard(rows: [
      KeyValueRow('Opening balance', value: 'NPR 58,200'),
      KeyValueRow('Last reconciled', value: '30 Sep 2026'),
    ])));
    expect(find.text('Opening balance'), findsOneWidget);
    expect(find.text('30 Sep 2026'), findsOneWidget);
  });

  testWidgets('SectionHeader in caps upper-cases its title', (tester) async {
    await tester.pumpWidget(wrap(const SectionHeader(title: 'Today · 14 Oct 2026', caps: true)));
    expect(find.text('TODAY · 14 OCT 2026'), findsOneWidget);
  });

  testWidgets('FieldGroup labels its input; ToggleRow flips its value', (tester) async {
    var on = false;
    await tester.pumpWidget(wrap(StatefulBuilder(builder: (context, setState) {
      return FieldGroup(
        label: 'Account type',
        child: ToggleRow(
          title: 'Update balance automatically from SMS',
          subtitle: 'Confident Dr/Cr messages are saved instantly.',
          value: on,
          onChanged: (v) => setState(() => on = v),
        ),
      );
    })));
    expect(find.text('Account type'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Update balance automatically from SMS'));
    await tester.pump();
    expect(on, isTrue);
  });

  testWidgets('TransactionTile shows a signed amount that masks with hide balances', (tester) async {
    const view = TxnView(
      title: 'Big Mart', subtitle: 'Groceries · eSewa', sign: kMinus, amount: 218000, tone: AmountTone.ink,
      icon: PaisaIcons.cart, iconTone: Tone.neutral, meta: 'SMS · 18:02', dateText: '9 Oct',
    );
    var tapped = false;
    await tester.pumpWidget(ProviderScope(child: wrap(TransactionTile(view: view, onTap: () => tapped = true))));
    expect(find.text('− NPR 2,180'), findsOneWidget);
    expect(find.text('9 Oct'), findsOneWidget);
    await tester.tap(find.text('Big Mart'));
    expect(tapped, isTrue);

    final container = ProviderScope.containerOf(tester.element(find.byType(TransactionTile)));
    container.read(hideBalancesProvider.notifier).toggle();
    await tester.pump();
    expect(find.textContaining('2,180'), findsNothing);
  });

  testWidgets('showUndoToast runs the undo once and confirms', (tester) async {
    var runs = 0;
    await tester.pumpWidget(ProviderScope(child: Consumer(builder: (context, ref, _) {
      return MaterialApp(
        theme: paisaTheme(PaisaColors.night),
        builder: (context, child) => PaisaToastHost(child: child!),
        home: Scaffold(
          body: TextButton(
            onPressed: () => showUndoToast(ref.read(toastProvider.notifier), 'Expense saved · NPR 1,500',
                UndoAction(() async => runs++)),
            child: const Text('go'),
          ),
        ),
      );
    })));
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.text('Expense saved · NPR 1,500'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(runs, 1);
    expect(find.text('Change undone'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
    await tester.pump(kUndoWindow);
  });
}
