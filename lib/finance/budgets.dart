import 'dart:math' as math;

import 'dates.dart';
import 'money.dart';

enum BudgetState { ok, nearLimit, over }

/// Alerts fire at 85% and when spending passes the limit (spec §11).
const double kBudgetWarnRatio = 0.85;

class BudgetLine {
  BudgetLine({required this.categoryId, required this.limit, required Paisa spent})
      : spent = spent < 0 ? 0 : spent;

  final String categoryId;

  /// 0 = no budget set.
  final Paisa limit;

  /// Net of refunds, never below zero.
  final Paisa spent;

  double get ratio => limit > 0 ? spent / limit : 0;
  Paisa get remaining => limit - spent;
  BudgetState get state {
    if (limit <= 0) return BudgetState.ok;
    if (spent > limit) return BudgetState.over;
    if (ratio >= kBudgetWarnRatio) return BudgetState.nearLimit;
    return BudgetState.ok;
  }
}

const int kEmergencyFundMonths = 6;

/// Essential monthly budgets × 6 (spec §7, Plans → Goals).
Paisa emergencyFundTarget(Paisa essentialMonthly) => essentialMonthly * kEmergencyFundMonths;

double emergencyFundMonths({required Paisa essentialMonthly, required Paisa saved}) =>
    essentialMonthly <= 0 ? 0 : saved / essentialMonthly;

/// Monthly amount that reaches [target] by [targetDate]; null without a date.
/// A past or current-month date asks for the full remainder now.
Paisa? recommendedMonthlySaving({
  required Paisa target,
  required Paisa current,
  required IsoDate today,
  IsoDate? targetDate,
}) {
  final remaining = target - current;
  if (remaining <= 0) return 0;
  if (targetDate == null) return null;
  final months = math.max(1, monthsUntil(today, targetDate));
  return (remaining / months).ceil();
}
