import 'package:flutter_test/flutter_test.dart';

import '../app_harness.dart';

/// What someone sees the first time they open a freshly installed Paisa.
void main() {
  testWidgets('Home starts at zero, invites adding an account, and shows no loans', (tester) async {
    await pumpPaisa(tester, cleanInstall: true);
    expect(tester.takeException(), isNull);
    expect(find.text('AVAILABLE TO SPEND'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2), reason: 'the balance, and the savings score ring');
    expect(find.text('Add eSewa, Khalti or bank'), findsOneWidget);
    expect(find.text('Loans remaining'), findsNothing);
    await scrollPageTo(tester, find.text('No transactions yet.'));
    expect(find.text('No transactions yet.'), findsOneWidget);
  });

  testWidgets('Accounts shows an empty state with Add account, and no loans section', (tester) async {
    await pumpPaisa(tester, location: '/accounts', cleanInstall: true);
    expect(find.text('No accounts yet'), findsOneWidget);
    expect(find.text('View loans & schedules'), findsNothing);
    await tester.tap(find.text('Add your first account'));
    await tester.pumpAndSettle();
    expect(find.text('Quick pick'), findsOneWidget);
  });

  testWidgets('Activity says there is nothing yet', (tester) async {
    await pumpPaisa(tester, location: '/activity', cleanInstall: true);
    expect(find.text('No transactions here'), findsOneWidget);
  });

  testWidgets('the forms ask for an account first', (tester) async {
    await pumpPaisa(tester, location: '/expense/new', cleanInstall: true);
    expect(find.text('Add an account first'), findsOneWidget);
  });
}
