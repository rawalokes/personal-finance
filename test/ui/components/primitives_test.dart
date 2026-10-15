import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/finance/money.dart';
import 'package:paisa/store/ui_state.dart';
import 'package:paisa/ui/components/buttons.dart';
import 'package:paisa/ui/components/indicators.dart';
import 'package:paisa/ui/components/inputs.dart';
import 'package:paisa/ui/components/money_text.dart';
import 'package:paisa/ui/components/surfaces.dart';
import 'package:paisa/ui/components/tone.dart';
import 'package:paisa/ui/icons/paisa_icons.dart';

import '../helpers.dart';

void main() {
  testWidgets('MoneyText uses lakh grouping and hides balances on toggle', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: wrap(const MoneyText(14235000)),
    ));
    expect(find.text('NPR 1,42,350'), findsOneWidget);
    container.read(hideBalancesProvider.notifier).toggle();
    await tester.pump();
    expect(find.text('NPR ••••••'), findsOneWidget);
    container.read(hideBalancesProvider.notifier).toggle();
    container.read(groupingProvider.notifier).set(Grouping.international);
    await tester.pump();
    expect(find.text('NPR 142,350'), findsOneWidget);
  });

  testWidgets('MoneyText signed and short forms', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: wrap(const Column(children: [
        MoneyText(150000, sign: '+'),
        MoneyText(14235000, short: true),
      ])),
    ));
    expect(find.text('+ NPR 1,500'), findsOneWidget);
    expect(find.text('1.42L'), findsOneWidget);
  });

  testWidgets('PaisaButton calls back only when enabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrap(Column(children: [
      PaisaButton(label: 'Save expense', onPressed: () => taps++),
      const PaisaButton(label: 'Disabled', onPressed: null, variant: ButtonVariant.outline),
    ])));
    await tester.tap(find.text('Save expense'));
    await tester.tap(find.text('Disabled'));
    expect(taps, 1);
    expect(tester.getSize(find.byType(PaisaButton).first).height, greaterThanOrEqualTo(50));
  });

  testWidgets('PaisaIconButton has a 44 px target and a label', (tester) async {
    var taps = 0;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(Row(children: [
      PaisaIconButton(icon: PaisaIcons.search, label: 'Search transactions', onPressed: () => taps++, boxed: true),
    ])));
    await tester.tap(find.bySemanticsLabel('Search transactions'));
    expect(taps, 1);
    expect(tester.getSize(find.byType(PaisaIconButton)), const Size(44, 44));
    handle.dispose();
  });

  testWidgets('Segmented reports the tapped value and marks the selection', (tester) async {
    String? picked;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(Segmented<String>(
      segments: const [('history', 'History'), ('inbox', 'Transaction Inbox')],
      selected: 'history',
      onChanged: (v) => picked = v,
    )));
    await tester.tap(find.text('Transaction Inbox'));
    expect(picked, 'inbox');
    expect(tester.getSemantics(find.text('History')), isSemantics(isSelected: true));
    handle.dispose();
  });

  testWidgets('PaisaToggle flips and exposes toggled state', (tester) async {
    var on = false;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(StatefulBuilder(
      builder: (context, setState) => PaisaToggle(
        value: on,
        label: 'Update balance automatically from SMS',
        onChanged: (v) => setState(() => on = v),
      ),
    )));
    await tester.tap(find.bySemanticsLabel('Update balance automatically from SMS'));
    await tester.pumpAndSettle();
    expect(on, isTrue);
    expect(tester.getSemantics(find.bySemanticsLabel('Update balance automatically from SMS')),
        isSemantics(isToggled: true));
    expect(tester.getSize(find.byType(PaisaToggle)).height, greaterThanOrEqualTo(44));
    handle.dispose();
  });

  testWidgets('PaisaChip selection is announced and has a 44 px target', (tester) async {
    var taps = 0;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(Row(children: [
      PaisaChip(label: 'eSewa', selected: true, onTap: () => taps++),
    ])));
    await tester.tap(find.text('eSewa'));
    expect(taps, 1);
    expect(tester.getSemantics(find.text('eSewa')), isSemantics(isSelected: true));
    expect(tester.getSize(find.byType(PaisaChip)).height, 44);
    handle.dispose();
  });

  testWidgets('ProgressBar clamps its value', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(const Column(children: [
      ProgressBar(value: 1.4, semanticLabel: 'Entertainment'),
      ProgressBar(value: double.nan, semanticLabel: 'Groceries'),
    ])));
    expect(tester.getSemantics(find.bySemanticsLabel('Entertainment')), isSemantics(value: '100%'));
    expect(tester.getSemantics(find.bySemanticsLabel('Groceries')), isSemantics(value: '0%'));
    handle.dispose();
  });

  testWidgets('ListRow, Tag, Note and IconWell render their content', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrap(Column(children: [
      PaisaListCard(children: [
        ListRow(
          title: 'Bhat-Bhateni Supermarket',
          subtitle: 'Groceries · Nabil ••4821',
          leading: const IconWell(icon: PaisaIcons.cart),
          trailing: const Tag('High confidence', tone: Tone.positive),
          onTap: () => taps++,
        ),
        const ListRow(title: 'Second row'),
      ]),
      const Note('Nothing is saved until you confirm it.', lead: 'Simulated SMS detection.'),
    ])));
    await tester.tap(find.text('Bhat-Bhateni Supermarket'));
    expect(taps, 1);
    expect(find.text('High confidence'), findsOneWidget);
    expect(find.text('Simulated SMS detection. Nothing is saved until you confirm it.'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
  });
}
