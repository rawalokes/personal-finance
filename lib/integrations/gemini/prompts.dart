import 'dart:convert';

/// Spec §9.4 system prompt. The engine computes every number; the AI only
/// explains and suggests.
const String kSystemPrompt = '''
You are Paisa's financial analyst for a user in Nepal. Amounts are NPR.
Use only the numbers in the provided JSON; never invent figures. If data is missing, say so.
Respect these accounting rules: transfers, loan principal, card bill payments, refunds and
reversals are not income or spending; loan disbursements are debt, not income.
Be concise, practical and kind. Prefer actions the user can take this month.
You are not a licensed financial adviser; do not recommend specific investment products.
Tax rates in the data may be unverified sample defaults; remind the user to verify them when relevant.
Respond only with JSON matching the given schema.''';

String _json(Object? data) => const JsonEncoder.withIndent(' ').convert(data);

String analysisPrompt(Map<String, Object?> summary) => '''
Analyse this month's finances. Give a health score from 0 to 100, a one-line headline, up to 5 findings,
up to 3 prioritised actions for this month (each with a deep link where relevant) and any risks.

DATA:
${_json(summary)}''';

String chatPrompt(Map<String, Object?> summary, List<(String, String)> history, String question) => '''
Answer the user's question in at most 5 short sentences, using only the data. List which parts of the
data you used (for example "loans", "budgets", "history"). Suggest one deep link if an action fits.

DATA:
${_json(summary)}

${history.isEmpty ? '' : 'EARLIER IN THIS CONVERSATION:\n${history.map((m) => '${m.$1}: ${m.$2}').join('\n')}\n\n'}QUESTION: $question''';

String explainPlanPrompt(Map<String, Object?> summary, Map<String, Object?> plan) => '''
Explain this loan payoff plan in plain language: why this order, what the extra payment changes, the
trade-offs (for example less money for savings goals), and a sustainable extra amount per month based on
the user's surplus history.

PLAN (computed by Paisa's engine — do not recompute):
${_json(plan)}

DATA:
${_json(summary)}''';

String budgetPrompt(Map<String, Object?> summary) => '''
Suggest a monthly budget limit for each spending category in "categories" that has spending or a
budget, using its "spentByMonth" history. Keep essentials realistic and suggest savings where spending
is high. Use each category's "categoryId" exactly as given; never invent categories.

DATA:
${_json(summary)}''';

String salaryCheckPrompt(Map<String, Object?> salary) => '''
Sanity-check this Nepal salary breakdown. Flag anything unusual (rates, caps, missing items), and remind
the user to verify sample tax and contribution rates with their payslip. Do not change any numbers.

SALARY (computed by Paisa's engine):
${_json(salary)}''';

String smsHelpPrompt({
  required String maskedSms,
  required String direction,
  required int amountNpr,
  required List<Map<String, String>> categories,
  required List<Map<String, String>> incomeTypes,
  required List<Map<String, String>> accounts,
}) => '''
A bank or wallet SMS could not be classified with confidence. Suggest the transaction type and, where it
applies, the category (expenses, refunds), income type (income) or the user's other account (transfers,
card payments, cash withdrawals). Use only the ids listed. Give a one-sentence reason. Account numbers
and balances in the SMS are masked.

SMS (masked): $maskedSms
DIRECTION: $direction
AMOUNT: NPR $amountNpr

CATEGORIES: ${_json(categories)}
INCOME TYPES: ${_json(incomeTypes)}
ACCOUNTS: ${_json(accounts)}''';
