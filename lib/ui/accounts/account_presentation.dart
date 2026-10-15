import '../../data/records.dart';
import '../../finance/finance.dart';
import '../components/tone.dart';
import '../icons/paisa_icons.dart';

String accountIcon(Account a) => switch (a.kind) {
      AccountKind.creditCard => PaisaIcons.card,
      AccountKind.wallet => PaisaIcons.phone,
      AccountKind.cash => PaisaIcons.cash,
      AccountKind.fixedDeposit => PaisaIcons.lock,
      AccountKind.cit || AccountKind.ssf => PaisaIcons.shield,
      _ => PaisaIcons.bank,
    };

/// Icon-well tone per group (mockup `avm.icCls`).
Tone accountTone(Account a) => switch (a.group) {
      AccountGroup.liquid => Tone.positive,
      AccountGroup.reserved => Tone.blue,
      AccountGroup.locked => Tone.neutral,
      AccountGroup.liability => Tone.red,
    };

const Map<AccountKind, String> _kindLabel = {
  AccountKind.bank: 'Bank account',
  AccountKind.savings: 'Savings account',
  AccountKind.wallet: 'Digital wallet',
  AccountKind.cash: 'Cash',
  AccountKind.creditCard: 'Credit card',
  AccountKind.fixedDeposit: 'Fixed deposit',
  AccountKind.cit: 'CIT balance',
  AccountKind.ssf: 'SSF balance',
  AccountKind.other: 'Other asset',
};

/// 'Digital wallet', 'Credit card', … from the configurable account types,
/// falling back to the kind.
String accountTypeLabel(Account a, Iterable<ConfigItem> accountTypes) {
  for (final t in accountTypes) {
    if (t.id == a.accountTypeId) return t.name;
  }
  return _kindLabel[a.kind]!;
}

/// Sections on the Accounts screen, in order (mockup `ac.groups`).
class AccountGroupInfo {
  const AccountGroupInfo(this.group, this.title, this.subtitle);
  final AccountGroup group;
  final String title;
  final String subtitle;
}

const kAccountGroups = [
  AccountGroupInfo(AccountGroup.liquid, 'Available · liquid', 'Spendable today'),
  AccountGroupInfo(AccountGroup.reserved, 'Reserved savings', 'Set aside — not in available balance'),
  AccountGroupInfo(AccountGroup.locked, 'Locked & retirement', 'FD, CIT and SSF — not withdrawable now'),
  AccountGroupInfo(AccountGroup.liability, 'Credit cards', 'Owed — counted in liabilities'),
];

/// Account detail tag text and tone (mockup `gt`).
(String, Tone) groupTag(AccountGroup g) => switch (g) {
      AccountGroup.liquid => ('Liquid · available', Tone.positive),
      AccountGroup.reserved => ('Reserved savings', Tone.blue),
      AccountGroup.locked => ('Locked', Tone.neutral),
      AccountGroup.liability => ('Liability', Tone.red),
    };

/// A liability with a positive balance is debt. Overpaid (below zero), the
/// card is in credit and must not be shown as owed.
bool isOwed(AccountGroup group, Paisa balance) => group == AccountGroup.liability && balance > 0;
bool isInCredit(AccountGroup group, Paisa balance) => group == AccountGroup.liability && balance < 0;

/// What a liability's amount displays as: always the size of the debt or
/// credit, with [owedSign] carrying the direction. Assets show as they are.
Paisa shownBalance(AccountGroup group, Paisa balance) => group == AccountGroup.liability ? balance.abs() : balance;

/// [kMinus] for money owed, nothing otherwise (amounts display as absolute).
String owedSign(AccountGroup group, Paisa balance) => isOwed(group, balance) ? kMinus : '';

/// Account detail "Counts toward" row.
String countsToward(AccountGroup g) => switch (g) {
      AccountGroup.liquid => 'Available balance',
      AccountGroup.reserved || AccountGroup.locked => 'Net worth only',
      AccountGroup.liability => 'Liabilities',
    };
