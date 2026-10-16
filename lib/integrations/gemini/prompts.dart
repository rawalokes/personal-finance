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

String lessonPrompt(Map<String, Object?> summary) => '''
Write today's short money lesson for this user: one habit or idea that would help them most right now,
based on their numbers (for example a category far above normal, low savings, a costly loan, no emergency
fund). Title at most 8 words. Body: 3 short paragraphs, plain words, under 160 words, mention their real
figures from the data. Takeaway: one action for this week, under 20 words. Encouraging, never shaming.

DATA:
${_json(summary)}''';

const _realityAsks = {
  'afford': '''
The user is thinking of buying something. FACTS holds Paisa's own verdict (yes / wait / no), the price, what is
free to spend this month after saving and EMIs, the hours of work it costs, how long it delays their nearest goal
and what the money becomes in 10 years. Give an honest reality check: agree with the verdict unless the facts
clearly say otherwise, explain it in their numbers, and say what to do instead if it is wait or no (for example
a cheaper option, saving for it over N months, or the wish list). Verdict must be yes, wait or no.''',
  'habits': '''
Give a frank reality check of the user's money habits from FACTS (EMI load, total debt in months of income,
savings rate, cash left after EMIs, emergency fund months, interest cost, biggest spending leaks, debt-free
date). Name the habit hurting them most. Verdict must be good, watch or bad. Actions: the three fixes that
matter most, each with a number.''',
  'goals': '''
Check whether the user's goals are realistic. FACTS lists each goal with Paisa's verdict, what it needs per month
and what the user really puts aside. For each goal that is a stretch or not realistic, say the trade-off: a later
date, a smaller target, or which spending to cut and by how much. Verdict must be good, watch or bad.''',
  'review': '''
Review this month: plan vs reality. FACTS has the savings target and what was saved, each budget against
spending, EMIs paid or missed, and Paisa's suggested fixes. Say what went well, what went wrong, and give next
month's fix in concrete numbers. Verdict must be good, watch or bad.''',
  'budget': '''
Explain this budget plan built by Paisa with the named method (50/30/20, zero-based or debt-first avalanche) from
the user's real spending. Say why this method suits them, which cuts matter most and how to stick to it. Do not
change the numbers. Verdict must be good, watch or bad (how hard the plan will be to keep).''',
};

String realityPrompt(String topic, Map<String, Object?> facts, Map<String, Object?> summary, {String? question}) => '''
${_realityAsks[topic] ?? _realityAsks['habits']!}
Headline: one honest sentence, at most 14 words. Points: up to 5 short sentences, each with a real figure.
Actions: up to 3 short steps. Be kind but never sugar-coat.
${question == null ? '' : '\nTHE USER ASKS: $question\n'}
FACTS (computed by Paisa's engine — do not recompute):
${_json(facts)}

DATA:
${_json(summary)}''';
