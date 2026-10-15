import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/ui/components/buttons.dart';
import 'package:paisa/ui/components/dialog.dart';
import 'package:paisa/ui/components/empty_state.dart';
import 'package:paisa/ui/components/sheet.dart';
import 'package:paisa/ui/components/skeleton.dart';
import 'package:paisa/ui/components/toast.dart';
import 'package:paisa/ui/icons/paisa_icons.dart';
import 'package:paisa/ui/theme.dart';
import 'package:paisa/ui/tokens.dart';

import '../helpers.dart';

void main() {
  testWidgets('bottom sheet shows title, body and footer and closes', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(Builder(
      builder: (ctx) => PaisaButton(
        label: 'Open',
        onPressed: () => showPaisaSheet<void>(ctx,
            title: 'Edit details', builder: (_) => const Text('Body'), footerBuilder: (_) => const Text('Footer')),
      ),
    )));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Edit details'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('Footer'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);
    handle.dispose();
  });

  testWidgets('confirm dialog returns ok, alt, or null for Cancel', (tester) async {
    final results = <ConfirmChoice?>[];
    await tester.pumpWidget(wrap(Builder(
      builder: (ctx) => PaisaButton(
        label: 'Open',
        onPressed: () async => results.add(await showConfirmDialog(
          ctx,
          title: 'This looks like a duplicate',
          body: 'Saving both would count this purchase twice.',
          okLabel: 'Ignore duplicate',
          altLabel: 'Save anyway',
        )),
      ),
    )));
    for (final button in ['Ignore duplicate', 'Save anyway', 'Cancel']) {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('This looks like a duplicate'), findsOneWidget);
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
    }
    expect(results, [ConfirmChoice.ok, ConfirmChoice.alt, null]);
  });

  testWidgets('toast offers Undo and disappears after 5 seconds', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: paisaTheme(PaisaColors.night),
        builder: (context, child) => PaisaToastHost(child: child!),
        home: const Scaffold(),
      ),
    ));
    var undone = 0;
    container.read(toastProvider.notifier).show('Expense saved · NPR 2,450', onUndo: () => undone++);
    await tester.pump();
    expect(find.text('Expense saved · NPR 2,450'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(undone, 1);
    expect(find.text('Expense saved · NPR 2,450'), findsNothing);

    container.read(toastProvider.notifier).show('Category updated');
    await tester.pump();
    expect(find.text('Undo'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Category updated'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Category updated'), findsNothing);
  });

  testWidgets('empty state shows its action', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrap(EmptyState(
      icon: PaisaIcons.search,
      title: 'No transactions here',
      body: 'Nothing matches this filter and date range.',
      actionLabel: 'Show all transactions',
      onAction: () => taps++,
    )));
    expect(find.text('No transactions here'), findsOneWidget);
    await tester.tap(find.text('Show all transactions'));
    expect(taps, 1);
  });

  testWidgets('skeleton announces loading and animates', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(const Skeleton(width: 120)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    handle.dispose();
  });
}
