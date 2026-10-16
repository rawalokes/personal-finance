/// Learn: short money lessons for Nepal, written for Paisa from the sources
/// listed on each lesson. Body text: paragraphs separated by a blank line;
/// lines starting with '• ' are bullets.
class LessonSource {
  const LessonSource(this.label, this.url);
  final String label;
  final String url;
}

enum LessonTopic {
  habits('Saving habits'),
  budgeting('Budgeting'),
  debt('Loans & debt'),
  growing('Growing money'),
  safety('Staying safe');

  const LessonTopic(this.label);
  final String label;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.topic,
    required this.title,
    required this.summary,
    required this.minutes,
    required this.body,
    this.sources = const [],
    this.tryInPaisa,
  });

  final String id;
  final LessonTopic topic;
  final String title;
  final String summary;
  final int minutes;
  final String body;
  final List<LessonSource> sources;

  /// One concrete step to take in the app.
  final String? tryInPaisa;
}

const _saveMoreTomorrow = LessonSource('Thaler & Benartzi — Save More Tomorrow', 'https://www.anderson.ucla.edu/faculty/shlomo.benartzi/savemore.htm');
const _ideas42 = LessonSource('ideas42 — Behavioral economics and savings', 'https://www.ideas42.org/wp-content/uploads/2015/05/A-Behavioral-Economics-Perspective-on-Innovations-in-Savings-Programs-1.pdf');
const _rule503020 = LessonSource('Western & Southern — The 50/30/20 rule', 'https://westernsouthern.com/personal-finance/50-30-20-rule');
const _chaseDebt = LessonSource('Chase — How much of your pay should go to debt', 'https://www.chase.com/personal/credit-cards/education/basics/how-much-of-your-paycheck-should-go-towards-debt');
const _jpalMalawi = LessonSource('J-PAL — Saving for multiple needs (Malawi)', 'https://povertyactionlab.org/media/file-research-paper/saving-multiple-financial-needs-evidence-malawi');
const _colombia = LessonSource('Cenfri — Public vs private mental accounts (Colombia)', 'https://cenfri.org/research-paper/public-vs-private-mental-accounts-empirical-evidence-from-savings-groups-in-colombia/');
const _fewerGoals = LessonSource('Cenfri — The fewer the better: number of goals and saving', 'https://cenfri.org/research-paper/the-fewer-the-better-number-of-goals-and-savings-behaviour/');
const _hershfield = LessonSource('NYU Stern — Hershfield: convincing people to save', 'https://www.stern.nyu.edu/experience-stern/faculty-research/hershfield-retirement-savings');
const _rule24 = LessonSource('Money Crashers — The 24-hour rule', 'https://www.moneycrashers.com/24-hour-rule-impulse-purchases/');
const _investorGov = LessonSource('Investor.gov — Compound interest calculator', 'https://www.investor.gov/financial-tools-calculators/calculators/compound-interest-calculator');
const _nrbFramework = LessonSource('Nepal Rastra Bank — Financial Literacy Framework', 'https://www.nrb.org.np/contents/uploads/2020/04/Financial-Literacy-Framework_20770114.pdf');
const _nrbSurvey = LessonSource('Nepal Rastra Bank — Financial literacy baseline survey', 'https://www.nrb.org.np/contents/uploads/2022/12/Baseline-Survey-on-Financial-Literacy-in-Nepal-including-Financial-Inclusion-Indicators.pdf');
const _salaryTax = LessonSource('Law Alpine — Salary tax in Nepal 2082/83', 'https://lawalpine.com/blog/salary-tax-calculator-nepal-2082-83');
const _ssf = LessonSource('Prime Law Nepal — Social Security Fund contributions', 'https://primelawnepal.com/?p=4049');
const _fraudPost = LessonSource('Kathmandu Post — Lure of easy money and online fraud', 'https://kathmandupost.com/national/2023/04/25/lure-of-easy-money-leads-nepalis-into-traps-of-online-fraudsters');
const _cyberBureau = LessonSource('Law Alpine — Cyber Bureau Nepal: how to complain', 'https://lawalpine.com/blog/cyber-bureau-nepal');

const kLessons = [
  Lesson(
    id: 'pay-yourself-first',
    topic: LessonTopic.habits,
    title: 'Pay yourself first',
    summary: 'Save on payday, not with what is left at the end of the month.',
    minutes: 2,
    body: '''Most people try to save what is left at the end of the month — and at the end of the month, nothing is left. Paying yourself first flips the order: the day your salary arrives, move your savings out before you spend anything.

Why it works: you spend what you can see. Money still sitting in your main account looks like spending money. Money already moved to a savings account or a goal looks like "already gone", so you plan around it.

Research on automatic saving shows the same thing. In the "Save More Tomorrow" study, people who decided in advance to save part of every future raise went from saving 3.5% of their pay to 11.6% within a few years — without feeling poorer.

• Pick a number: 10% to start, 20% when you can.
• Move it on payday, every time, before any shopping.
• Treat it like a bill you owe your future self.''',
    tryInPaisa: 'When income arrives, Paisa reminds you to move 20% to savings. Use Plans → Goals → Add money.',
    sources: [_saveMoreTomorrow, _ideas42],
  ),
  Lesson(
    id: 'budget-50-30-20',
    topic: LessonTopic.budgeting,
    title: 'The 50/30/20 budget, made for Nepal',
    summary: 'A simple split for your take-home pay: needs, wants and saving.',
    minutes: 3,
    body: '''The 50/30/20 rule splits your take-home pay into three parts:

• 50% for needs: rent, food, transport, utilities, school fees, loan EMIs.
• 30% for wants: eating out, shopping, Daraz orders, trips, entertainment.
• 20% for saving and paying off debt faster.

In Kathmandu, rent and EMIs often take more than half. That's fine — the rule is a starting point, not a law. If needs take 60%, trim wants to 20% and still protect saving. The one part to keep is the 20% for your future.

If 20% feels impossible, start with 5% and raise it by 1% every month. Small, steady increases are easier to keep than a big cut you give up after two weeks.''',
    tryInPaisa: 'Set monthly limits in Plans → Budgets. Mark rent, food and transport as essential.',
    sources: [_rule503020],
  ),
  Lesson(
    id: 'emergency-fund',
    topic: LessonTopic.habits,
    title: 'Build an emergency fund first',
    summary: '3–6 months of essential costs, kept apart, for the day something goes wrong.',
    minutes: 2,
    body: '''An emergency fund is money you never plan to spend — until a hospital bill, a job loss or a broken bike arrives. Without one, every surprise becomes a loan from a friend, a cooperative or a credit card, at high interest.

How much? Aim for 3 to 6 months of your essential costs: rent, food, transport, EMIs, school fees. Start with one month; that alone stops most small emergencies turning into debt.

Where to keep it: somewhere safe and quick to reach — a separate savings account in a licensed bank, not cash at home and not a cooperative promising high returns. Keep it apart from your everyday account so it doesn't slowly get spent.

Nepal Rastra Bank's financial literacy survey found that most adults still turn to family and friends when they need money. An emergency fund is how you stop needing to.''',
    tryInPaisa: 'Plans → Goals shows how many months your savings accounts cover.',
    sources: [_rule503020, _nrbSurvey],
  ),
  Lesson(
    id: 'track-every-rupee',
    topic: LessonTopic.budgeting,
    title: 'Know where every rupee goes',
    summary: 'You can’t cut spending you can’t see.',
    minutes: 2,
    body: '''Ask most people how much they spent on food last month and they guess low — often by a third. Small payments add up quietly: tea, eSewa top-ups, delivery charges, subscriptions.

Tracking for just one month is eye-opening. You don't need to judge every purchase; just see the totals by category. The surprises usually point to the easiest savings.

• Review once a week, not once a year.
• Look for the "leaks": things you'd never choose to spend that much on.
• Cut one leak at a time — the one that hurts least.''',
    tryInPaisa: 'Confirm bank and wallet SMS in the Transaction Inbox, then check Reports → Spending by category.',
    sources: [_nrbFramework],
  ),
  Lesson(
    id: 'needs-wants-24h',
    topic: LessonTopic.habits,
    title: 'Needs, wants and the 24-hour rule',
    summary: 'Wait a day before buying a want — most of the urge passes.',
    minutes: 2,
    body: '''A need is something you'd be in trouble without. A want is something nice to have. Both are fine — the problem is buying wants on impulse and then running short on needs.

The 24-hour rule is a simple brake: when you feel like buying something you don't need — say NPR 5,000 or more — wait one full day. If you still want it tomorrow and it fits your budget, buy it without guilt.

Desire is strongest the moment you see something and fades fast once you walk away. People who try the rule report that they forget about many of the things they "had to have".''',
    tryInPaisa: 'Adding a non-essential expense of NPR 5,000 or more offers "Wait 24 hours". Skipped items count as money saved.',
    sources: [_rule24],
  ),
  Lesson(
    id: 'labelled-jars',
    topic: LessonTopic.habits,
    title: 'Labelled jars: give every rupee a job',
    summary: 'Money with a name on it is harder to spend.',
    minutes: 2,
    body: '''Our grandparents kept money in different tins: one for school fees, one for Dashain, one for emergencies. Economists call this mental accounting — and it works.

When savings have a label ("Bike", "Emergency", "Dashain"), we're less likely to dip into them for everyday spending. In a field study in Malawi, people given separate labelled accounts saved about 30% more in them. In Colombia, savings groups who announced their goals publicly saved 35% more.

• Give each goal its own name and target.
• Keep goal money out of your spending account.
• Tell someone your goal — a little public commitment helps.''',
    tryInPaisa: 'Create named goals in Plans → Goals and add money to them as soon as income arrives.',
    sources: [_jpalMalawi, _colombia],
  ),
  Lesson(
    id: 'one-goal',
    topic: LessonTopic.habits,
    title: 'One goal at a time',
    summary: 'Fewer goals means more saved.',
    minutes: 1,
    body: '''It's tempting to save for a phone, a trip, a bike and a wedding all at once. Research on savings goals suggests that focusing on a single goal often leads to more saving than spreading attention across many.

Pick the one that matters most right now — usually your emergency fund — and finish it. Then move to the next. Each finished goal gives you the confidence to start the next one.''',
    tryInPaisa: 'Accept just one challenge a month in Plans → Challenges and see it through.',
    sources: [_fewerGoals],
  ),
  Lesson(
    id: 'future-you',
    topic: LessonTopic.habits,
    title: 'Meet your future self',
    summary: 'Seeing the person you’re saving for makes saving easier.',
    minutes: 2,
    body: '''Saving is hard partly because the person who benefits — you in 10 or 30 years — feels like a stranger. Researchers led by Hal Hershfield showed people pictures of their own faces aged to around 70. Those who saw their older selves chose to put noticeably more of their pay into retirement savings.

You don't need a photo filter. Try this:

• Picture yourself at 60: where you live, what you'd like to do.
• Write one sentence to that person about why you're saving today.
• Look at what your monthly saving becomes over 10 years.

NPR 5,000 a month at 8% a year becomes about NPR 9.1 lakh in 10 years — more than half of it from your own deposits, the rest from growth.''',
    tryInPaisa: 'Home → Save shows what this month’s target grows to in 10 years.',
    sources: [_hershfield],
  ),
  Lesson(
    id: 'compound-interest',
    topic: LessonTopic.growing,
    title: 'Compound interest and the rule of 72',
    summary: 'Interest on interest — for you when saving, against you when borrowing.',
    minutes: 2,
    body: '''Compound interest means you earn interest on your interest. NPR 1 lakh at 8% a year becomes 1.08 lakh after one year, 1.17 lakh after two, and about 2.16 lakh after ten — without adding anything.

The rule of 72 is a quick way to feel it: divide 72 by the interest rate to get the years it takes money to double. At 8%, about 9 years. At 6%, 12 years.

It works the same way against you. A loan or credit card at 24% doubles what you owe in about 3 years if you don't pay it down. That's why paying off expensive debt is one of the best "investments" you can make.''',
    tryInPaisa: 'Plans → Loans → Payoff planner shows how much interest an extra payment saves.',
    sources: [_investorGov],
  ),
  Lesson(
    id: 'how-emis-work',
    topic: LessonTopic.debt,
    title: 'How EMIs really work',
    summary: 'Early EMIs are mostly interest. Extra payments cut the most.',
    minutes: 3,
    body: '''An EMI (equated monthly installment) stays the same each month, but what's inside it changes. On a reducing-balance loan, interest is charged on what you still owe. Early on you owe the most, so most of the EMI is interest and only a little reduces the loan. Later the split flips.

Flat-rate loans charge interest on the original amount for the whole term. A "12% flat" loan costs much more than "12% reducing" — always ask which one you're being offered.

Before you sign:
• Ask for the interest method (reducing or flat), the total you'll repay and all fees.
• Ask about prepayment charges — can you pay early without a penalty?
• Check the EMI fits inside your budget's "needs", not your savings.

Even small extra payments early in a loan cut total interest and months off the term.''',
    tryInPaisa: 'Record repayments from the loan page; Paisa splits them into principal and interest.',
    sources: [_nrbFramework],
  ),
  Lesson(
    id: 'avalanche-snowball',
    topic: LessonTopic.debt,
    title: 'Paying off debt: avalanche or snowball',
    summary: 'Highest interest first saves the most; smallest first keeps you going.',
    minutes: 2,
    body: '''With more than one loan, pay the minimum on all of them and put every extra rupee on one loan at a time.

• Avalanche: put extra money on the loan with the highest interest rate. It saves the most interest overall.
• Snowball: put extra money on the smallest balance. You clear a loan sooner, and that quick win keeps you motivated.

When one loan is paid off, roll its whole EMI into the next. That's the "snowball" that speeds everything up. The best method is the one you'll actually stick with.''',
    tryInPaisa: 'The Payoff planner compares both methods with your real loans.',
    sources: [_rule503020, _chaseDebt],
  ),
  Lesson(
    id: 'credit-card-trap',
    topic: LessonTopic.debt,
    title: 'The minimum-payment trap',
    summary: 'Paying only the minimum can keep you in debt for years.',
    minutes: 2,
    body: '''Credit cards let you pay a small minimum each month. It feels manageable, but the rest keeps charging interest at a high yearly rate. A balance paid at the minimum can take years to clear and cost far more than the original purchase.

• Pay the full statement balance every month if you can.
• If you can't, pay as much above the minimum as possible and stop using the card until it's clear.
• Never use one card to pay another.

A useful guide: keep total debt payments well below a third of your take-home pay, so a surprise doesn't push you into more borrowing.''',
    tryInPaisa: 'Record card payments as "Card payment" so Paisa shows what you really owe.',
    sources: [_chaseDebt],
  ),
  Lesson(
    id: 'raise-rule',
    topic: LessonTopic.habits,
    title: 'Save half of every raise',
    summary: 'Beat lifestyle creep before it starts.',
    minutes: 1,
    body: '''When income goes up, spending quietly rises to match — a nicer phone, more eating out, a bigger flat. This "lifestyle creep" is why many people earn more each year but never feel ahead.

Decide now, before your next raise or bonus arrives: half of it goes to savings or extra loan payments. You still enjoy the other half, and you never miss what you never got used to spending. This is the heart of the Save More Tomorrow idea.''',
    tryInPaisa: 'When your salary goes up, raise your monthly challenge target by half the difference.',
    sources: [_saveMoreTomorrow],
  ),
  Lesson(
    id: 'ssf-cit-tax',
    topic: LessonTopic.growing,
    title: 'SSF, CIT and EPF: retirement saving that cuts your tax',
    summary: 'Contributions are deductible from taxable income, up to a limit.',
    minutes: 3,
    body: '''If you're salaried in Nepal, retirement funds are one of the few savings that also lower your income tax.

• Social Security Fund (SSF): employees contribute 11% of basic salary and employers add 20%.
• Citizen Investment Trust (CIT) and the Employees' Provident Fund (EPF) are other approved retirement funds.
• Contributions to approved retirement funds are deductible from taxable income — up to NPR 5 lakh a year or one-third of your taxable income, whichever is lower (FY 2082/83).
• Life insurance premiums (up to NPR 40,000) and health insurance (up to NPR 20,000) can also be deducted.

Tax rules change with each year's budget, so check the current limits with your employer, the Inland Revenue Department or a tax adviser before you rely on them.''',
    tryInPaisa: 'Settings → Salary shows how deductions change your take-home pay and tax.',
    sources: [_salaryTax, _ssf],
  ),
  Lesson(
    id: 'where-to-keep-savings',
    topic: LessonTopic.growing,
    title: 'Savings account, fixed deposit or cooperative?',
    summary: 'Safety first, then access, then return.',
    minutes: 3,
    body: '''Where you keep savings matters as much as how much you save. Judge each option in this order:

1. Safety — is the institution licensed and supervised by Nepal Rastra Bank?
2. Access — can you get the money when you need it?
3. Return — what interest does it actually pay after tax?

• Savings account: easy to reach, lower interest. Good for your emergency fund.
• Fixed deposit: higher interest, money locked for a term. Good for money you won't need for a while.
• Cooperatives: some are sound, but several have failed in recent years and savers lost money. An unusually high rate is a warning sign, not a bonus.

Spread large savings rather than keeping everything in one place.''',
    tryInPaisa: 'Mark fixed deposits as locked accounts so Free to spend never counts them.',
    sources: [_nrbFramework],
  ),
  Lesson(
    id: 'inflation',
    topic: LessonTopic.growing,
    title: 'Why cash at home loses value',
    summary: 'Prices rise every year; money that sits still buys less.',
    minutes: 2,
    body: '''Inflation means prices rise over time. If prices go up 5% a year, NPR 1 lakh kept in a drawer buys only about NPR 61,000 worth of today's goods after 10 years.

That's why savings should earn interest that at least keeps up with rising prices. A savings account or fixed deposit won't make you rich, but it protects your money from quietly shrinking. For long-term goals, retirement funds and well-understood investments can do more — after your emergency fund is in place.''',
    tryInPaisa: 'Keep only small amounts as Cash in Paisa; move the rest to an account that pays interest.',
    sources: [_nrbFramework],
  ),
  Lesson(
    id: 'scams-nepal',
    topic: LessonTopic.safety,
    title: 'Common money scams in Nepal',
    summary: 'No real bank or wallet will ever ask for your OTP.',
    minutes: 3,
    body: '''Online fraud in Nepal has grown fast — complaints to police nearly doubled in a single year. Most scams follow a few patterns:

• "KYC update" or "account blocked" calls and links pretending to be your bank, eSewa or Khalti.
• Requests for your OTP, PIN or password. A real bank or wallet never asks for them.
• Fake lottery, prize or gift messages that ask for a "processing fee".
• Overseas job and Telegram/WhatsApp "work from home" offers that want money first.
• Investment schemes promising very high, guaranteed returns.

If something feels urgent and secret, stop. Hang up and call your bank's official number yourself. If you've been cheated, report it quickly to Nepal Police's Cyber Bureau (hotline 100) with screenshots and transaction details.''',
    tryInPaisa: 'Paisa only reads SMS from bank and wallet senders you trust, and never asks for passwords or OTPs.',
    sources: [_fraudPost, _cyberBureau],
  ),
  Lesson(
    id: 'insurance-basics',
    topic: LessonTopic.safety,
    title: 'Insurance: protect what you’ve saved',
    summary: 'One hospital bill can undo years of saving.',
    minutes: 2,
    body: '''Insurance is not an investment — it's protection. Its job is to stop one bad event from wiping out your savings or pushing you into debt.

• Health insurance comes first: hospital bills are the most common financial shock.
• Term life insurance matters if others depend on your income. It's usually much cheaper than plans mixed with investment.
• Read what's covered and what isn't before you buy.

Premiums for life insurance (up to NPR 40,000) and health insurance (up to NPR 20,000) can reduce your taxable income — check the current year's limits.''',
    tryInPaisa: 'Add premiums as a recurring expense so they’re always in your plan.',
    sources: [_salaryTax],
  ),
  Lesson(
    id: 'payday-routine',
    topic: LessonTopic.budgeting,
    title: 'A 10-minute payday routine',
    summary: 'The same five steps every payday keep your month on track.',
    minutes: 2,
    body: '''Good money habits are boring on purpose. Do these five things every payday, in this order:

• Move your savings first (pay yourself first).
• Set aside EMIs and bills due this month.
• Check last month: which category went over, and why?
• Set this month's one challenge.
• Whatever is left is truly free to spend — enjoy it without guilt.

Ten minutes once a month beats worrying about money every day.''',
    tryInPaisa: 'Home shows this month’s plan: save, EMIs, budgets and what’s free to spend.',
    sources: [_ideas42],
  ),
  Lesson(
    id: 'health-checklist',
    topic: LessonTopic.budgeting,
    title: 'Your money health checklist',
    summary: 'Seven questions to see where you stand.',
    minutes: 2,
    body: '''Answer honestly; each "no" is your next step.

• Do I know what I spent last month, by category?
• Do I save something every month, on payday?
• Do I have at least one month of essential costs saved? Three?
• Are my debt payments well under a third of my take-home pay?
• Do I know the interest method and total cost of each loan?
• Am I covered by health insurance?
• Am I contributing to a retirement fund (SSF, CIT or EPF)?

You don't need all seven at once. Fix one this month.''',
    tryInPaisa: 'Your savings score on Home and Reports tracks several of these automatically.',
    sources: [_nrbFramework, _nrbSurvey],
  ),
];
