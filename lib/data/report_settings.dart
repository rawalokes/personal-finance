import '../finance/finance.dart';
import 'settings_models.dart' show Json;

enum ReportChart {
  bar('Bar'),
  line('Line'),
  donut('Donut'),
  list('List');

  const ReportChart(this.label);
  final String label;
}

enum WidgetSize { half, full }

/// The settings a widget's ⚙ sheet offers.
enum WidgetSetting { period, accounts, categories, loans, groupBy, compare }

/// Dashboard widget types (spec §3.1).
enum ReportWidgetType {
  savingsScore('savings_score', 'Savings score', 'Your monthly score and the one change that raises it most'),
  cashFlow('cash_flow', 'Cash flow', 'Money in vs out each month'),
  spendingByCategory('spending_by_category', 'Spending by category', 'Where your money goes'),
  incomeBySource('income_by_source', 'Income by source', 'Income by type or by who paid you'),
  netWorth('net_worth', 'Net worth', 'What you own minus what you owe, month by month'),
  assetsLiabilities('assets_liabilities', 'Assets vs liabilities', 'Today, with your debt-to-asset ratio'),
  budgetPerformance('budget_performance', 'Budgets', 'Spent vs limit this month'),
  loanProgress('loan_progress', 'Loan progress', 'How much is repaid and when each loan ends'),
  interestPaid('interest_paid', 'Interest paid', 'Loan interest each month'),
  savingsRate('savings_rate', 'Savings rate', 'Share of income you kept each month'),
  topPayees('top_payees', 'Top payees', 'Who you paid the most'),
  challenges('challenges', 'Challenges', 'This month’s challenges and your streak');

  const ReportWidgetType(this.wire, this.title, this.description);
  final String wire;
  final String title;
  final String description;

  static ReportWidgetType? fromWire(String w) => values.where((t) => t.wire == w).firstOrNull;

  /// Charts this type can draw; the first is its default.
  List<ReportChart> get charts => switch (this) {
        cashFlow || interestPaid => const [ReportChart.bar, ReportChart.line],
        spendingByCategory || incomeBySource => const [ReportChart.donut, ReportChart.bar, ReportChart.list],
        netWorth || savingsRate => const [ReportChart.line, ReportChart.bar],
        assetsLiabilities => const [ReportChart.bar, ReportChart.list],
        topPayees => const [ReportChart.list, ReportChart.bar],
        savingsScore || budgetPerformance || loanProgress || challenges => const [ReportChart.list],
      };

  Set<WidgetSetting> get settings => switch (this) {
        cashFlow => const {WidgetSetting.period, WidgetSetting.accounts, WidgetSetting.compare},
        spendingByCategory => const {WidgetSetting.period, WidgetSetting.accounts, WidgetSetting.categories, WidgetSetting.compare},
        incomeBySource => const {WidgetSetting.period, WidgetSetting.accounts, WidgetSetting.groupBy, WidgetSetting.compare},
        netWorth => const {WidgetSetting.period},
        budgetPerformance => const {WidgetSetting.categories},
        loanProgress => const {WidgetSetting.loans},
        interestPaid => const {WidgetSetting.period, WidgetSetting.loans, WidgetSetting.compare},
        savingsRate => const {WidgetSetting.period, WidgetSetting.accounts},
        topPayees => const {WidgetSetting.period, WidgetSetting.accounts, WidgetSetting.compare},
        assetsLiabilities || savingsScore || challenges => const {},
      };
}

List<String> _ids(Object? v) => v is List ? [for (final x in v) if (x is String) x] : const [];

/// One widget on the dashboard and how it is set up (spec §3.2).
class ReportWidgetConfig {
  const ReportWidgetConfig({
    required this.id,
    required this.type,
    required this.chart,
    this.period = ReportPeriod.thisMonth,
    this.accountIds = const [],
    this.categoryIds = const [],
    this.loanIds = const [],
    this.groupBy = IncomeGrouping.type,
    this.size = WidgetSize.full,
    this.compare = false,
  });

  /// A new widget of [type] with its defaults: trends start at 6 months.
  factory ReportWidgetConfig.create(String id, ReportWidgetType type) => ReportWidgetConfig(
        id: id,
        type: type,
        chart: type.charts.first,
        period: const {
          ReportWidgetType.cashFlow,
          ReportWidgetType.netWorth,
          ReportWidgetType.interestPaid,
          ReportWidgetType.savingsRate,
        }.contains(type)
            ? ReportPeriod.last6m
            : ReportPeriod.thisMonth,
      );

  final String id;
  final ReportWidgetType type;
  final ReportPeriod period;

  /// Empty = all.
  final List<String> accountIds;
  final List<String> categoryIds;
  final List<String> loanIds;
  final IncomeGrouping groupBy;
  final ReportChart chart;
  final WidgetSize size;

  /// Also show the previous period of the same length.
  final bool compare;

  ReportWidgetConfig copyWith({
    ReportPeriod? period,
    List<String>? accountIds,
    List<String>? categoryIds,
    List<String>? loanIds,
    IncomeGrouping? groupBy,
    ReportChart? chart,
    WidgetSize? size,
    bool? compare,
  }) =>
      ReportWidgetConfig(
        id: id,
        type: type,
        chart: chart ?? this.chart,
        period: period ?? this.period,
        accountIds: accountIds ?? this.accountIds,
        categoryIds: categoryIds ?? this.categoryIds,
        loanIds: loanIds ?? this.loanIds,
        groupBy: groupBy ?? this.groupBy,
        size: size ?? this.size,
        compare: compare ?? this.compare,
      );

  Json toJson() => {
        'id': id,
        'type': type.wire,
        'period': period.wire,
        'accountIds': accountIds,
        'categoryIds': categoryIds,
        'loanIds': loanIds,
        'groupBy': groupBy.name,
        'chart': chart.name,
        'size': size.name,
        'compare': compare,
      };

  /// Null for a type this version doesn't know.
  static ReportWidgetConfig? fromJson(Json j) {
    final type = ReportWidgetType.fromWire(j['type'] as String? ?? '');
    final id = j['id'];
    if (type == null || id is! String) return null;
    final chart = ReportChart.values.where((c) => c.name == j['chart']).firstOrNull;
    return ReportWidgetConfig(
      id: id,
      type: type,
      chart: chart != null && type.charts.contains(chart) ? chart : type.charts.first,
      period: ReportPeriod.fromWire(j['period'] as String? ?? ''),
      accountIds: _ids(j['accountIds']),
      categoryIds: _ids(j['categoryIds']),
      loanIds: _ids(j['loanIds']),
      groupBy: j['groupBy'] == IncomeGrouping.party.name ? IncomeGrouping.party : IncomeGrouping.type,
      size: j['size'] == WidgetSize.half.name ? WidgetSize.half : WidgetSize.full,
      compare: j['compare'] == true,
    );
  }
}

class DashboardConfig {
  const DashboardConfig(this.widgets);
  final List<ReportWidgetConfig> widgets;

  Json toJson() => {'version': 1, 'widgets': [for (final w in widgets) w.toJson()]};

  /// Throws [FormatException] when the document has no widget list.
  static DashboardConfig fromJson(Json j) {
    final list = j['widgets'];
    if (list is! List) throw const FormatException('reports.dashboard has no widget list');
    return DashboardConfig([
      for (final w in list)
        if (w is Map) ?ReportWidgetConfig.fromJson(w.cast<String, Object?>()),
    ]);
  }
}

/// What Reports shows before the user changes anything (spec §3.3).
DashboardConfig defaultDashboard() => DashboardConfig([
      ReportWidgetConfig.create('w-score', ReportWidgetType.savingsScore),
      ReportWidgetConfig.create('w-cash', ReportWidgetType.cashFlow),
      ReportWidgetConfig.create('w-spend', ReportWidgetType.spendingByCategory).copyWith(size: WidgetSize.half),
      ReportWidgetConfig.create('w-budget', ReportWidgetType.budgetPerformance).copyWith(size: WidgetSize.half),
      ReportWidgetConfig.create('w-loans', ReportWidgetType.loanProgress),
      ReportWidgetConfig.create('w-challenges', ReportWidgetType.challenges),
    ]);

/// Drops ids of accounts, categories and loans that no longer exist.
DashboardConfig normaliseDashboard(
  DashboardConfig d, {
  required Set<String> accountIds,
  required Set<String> categoryIds,
  required Set<String> loanIds,
}) =>
    DashboardConfig([
      for (final w in d.widgets)
        w.copyWith(
          accountIds: [for (final id in w.accountIds) if (accountIds.contains(id)) id],
          categoryIds: [for (final id in w.categoryIds) if (categoryIds.contains(id)) id],
          loanIds: [for (final id in w.loanIds) if (loanIds.contains(id)) id],
        ),
    ]);

/// Dismissed nudges (id → last hidden day) and kinds turned off.
class NudgeState {
  const NudgeState({this.dismissed = const {}, this.disabled = const {}});
  final Map<String, IsoDate> dismissed;
  final Set<NudgeKind> disabled;

  /// Hidden today and the next 6 days; expired entries are dropped.
  NudgeState dismiss(String id, IsoDate today) => NudgeState(
        dismissed: {
          for (final e in dismissed.entries)
            if (e.value.compareTo(today) >= 0) e.key: e.value,
          id: toIsoDate(parseIsoDate(today).add(const Duration(days: 6))),
        },
        disabled: disabled,
      );

  NudgeState withKind(NudgeKind kind, {required bool enabled}) => NudgeState(
        dismissed: dismissed,
        disabled: enabled ? ({...disabled}..remove(kind)) : {...disabled, kind},
      );

  Json toJson() => {'dismissed': dismissed, 'disabledKinds': [for (final k in disabled) k.wire]};

  static NudgeState fromJson(Json j) {
    final d = j['dismissed'];
    final k = j['disabledKinds'];
    return NudgeState(
      dismissed: d is Map ? {for (final e in d.entries) if (e.key is String && e.value is String) e.key as String: e.value as String} : const {},
      disabled: k is List ? {for (final w in k) ?NudgeKind.fromWire('$w')} : const {},
    );
  }
}

Json _challengeToJson(Challenge c) => {
      'id': c.id,
      'template': c.template.wire,
      'month': c.month,
      'target': c.target,
      'categoryId': c.categoryId,
      'loanId': c.loanId,
      'accepted': c.accepted,
      'source': c.source.name,
    };

Challenge _challengeFromJson(Json j) => Challenge(
      id: j['id'] as String,
      template: ChallengeTemplate.fromWire(j['template'] as String),
      month: j['month'] as String,
      target: (j['target'] as num).toInt(),
      categoryId: j['categoryId'] as String?,
      loanId: j['loanId'] as String?,
      accepted: j['accepted'] != false,
      source: j['source'] == ChallengeSource.suggested.name ? ChallengeSource.suggested : ChallengeSource.user,
    );

Json challengeStateToJson(ChallengeState s) => {
      'active': [for (final c in s.active) _challengeToJson(c)],
      'history': [for (final r in s.history) {'challenge': _challengeToJson(r.challenge), 'done': r.done}],
      'badges': [for (final b in s.badges) b.wire],
      'lastSuggestedMonth': s.lastSuggestedMonth,
    };

ChallengeState challengeStateFromJson(Json j) => ChallengeState(
      active: [for (final c in (j['active'] as List? ?? const [])) _challengeFromJson((c as Map).cast<String, Object?>())],
      history: [
        for (final r in (j['history'] as List? ?? const []))
          ChallengeResult(_challengeFromJson(((r as Map)['challenge'] as Map).cast<String, Object?>()), r['done'] == true),
      ],
      badges: {for (final b in (j['badges'] as List? ?? const [])) ?BadgeId.fromWire('$b')},
      lastSuggestedMonth: j['lastSuggestedMonth'] as String?,
    );

Json waitListToJson(WaitList w) => {
      'items': [
        for (final i in w.items)
          {
            'id': i.id, 'title': i.title, 'amount': i.amount, 'addedAt': i.addedAt, 'categoryId': i.categoryId, 'accountId': i.accountId,
            'wish': i.wish, 'priority': i.priority,
          },
      ],
      'savedByWaiting': w.savedByWaiting,
    };

WaitList waitListFromJson(Json j) => WaitList(
      items: [
        for (final raw in (j['items'] as List? ?? const []))
          if (raw is Map)
            WaitItem(
              id: raw['id'] as String,
              title: raw['title'] as String,
              amount: (raw['amount'] as num).toInt(),
              addedAt: raw['addedAt'] as String,
              categoryId: raw['categoryId'] as String?,
              accountId: raw['accountId'] as String?,
              wish: raw['wish'] == true,
              priority: ((raw['priority'] as num?)?.toInt() ?? 2).clamp(1, 3),
            ),
      ],
      savedByWaiting: (j['savedByWaiting'] as num?)?.toInt() ?? 0,
    );
