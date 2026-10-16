/// Saving quotes for the Home quote card. Attribution matters: many quotes
/// online are credited to the wrong person, so anything without a solid
/// source says "attributed to", and the famous Einstein one says so plainly.
class Quote {
  const Quote(this.text, this.author, {this.attributed = false, this.translation});

  final String text;
  final String author;

  /// True when the quote is widely credited to [author] but not documented.
  final bool attributed;

  /// English meaning, for Nepali proverbs.
  final String? translation;

  String get byline => attributed ? 'attributed to $author' : author;
}

const kQuotes = [
  Quote('Beware of little expenses; a small leak will sink a great ship.', 'Benjamin Franklin, The Way to Wealth (1758)'),
  Quote('If you would be wealthy, think of saving as well as getting.', 'Benjamin Franklin, The Way to Wealth (1758)'),
  Quote('Do not save what is left after spending, but spend what is left after saving.', 'Warren Buffett', attributed: true),
  Quote('Price is what you pay. Value is what you get.', 'Warren Buffett, 2008 letter to shareholders'),
  Quote('Rule No. 1: Never lose money. Rule No. 2: Never forget rule No. 1.', 'Warren Buffett', attributed: true),
  Quote('Someone is sitting in the shade today because someone planted a tree a long time ago.', 'Warren Buffett', attributed: true),
  Quote('The stock market is a device for transferring money from the impatient to the patient.', 'Warren Buffett', attributed: true),
  Quote(
    'Annual income twenty pounds, annual expenditure nineteen nineteen and six, result happiness. Annual income twenty pounds, annual expenditure twenty pounds ought and six, result misery.',
    'Mr Micawber in Charles Dickens, David Copperfield (1850)',
  ),
  Quote('Never spend your money before you have it.', 'Thomas Jefferson, letter to Thomas Jefferson Smith (1825)'),
  Quote('It is not the man who has too little, but the man who craves more, that is poor.', 'Seneca, Letters to Lucilius'),
  Quote('Wealth consists not in having great possessions, but in having few wants.', 'Epictetus', attributed: true),
  Quote('Building wealth has little to do with your income or investment returns, and lots to do with your savings rate.', 'Morgan Housel, The Psychology of Money (2020)'),
  Quote('Wealth is what you don’t see.', 'Morgan Housel, The Psychology of Money (2020)'),
  Quote('Spending money to show people how much money you have is the fastest way to have less money.', 'Morgan Housel, The Psychology of Money (2020)'),
  Quote('Too many people spend money they earned to buy things they don’t want to impress people they don’t like.', 'Will Rogers', attributed: true),
  Quote('A budget is telling your money where to go instead of wondering where it went.', 'John C. Maxwell', attributed: true),
  Quote('You must gain control over your money or the lack of it will forever control you.', 'Dave Ramsey', attributed: true),
  Quote('Don’t tell me what you value. Show me your budget, and I’ll tell you what you value.', 'Joe Biden, quoting his father'),
  Quote('The habit of saving is itself an education; it fosters every virtue, teaches self-denial and trains to forethought.', 'T. T. Munger', attributed: true),
  Quote('Money is a terrible master but an excellent servant.', 'P. T. Barnum', attributed: true),
  Quote('It’s not your salary that makes you rich, it’s your spending habits.', 'Charles A. Jaffe', attributed: true),
  Quote('Every time you borrow money, you’re robbing your future self.', 'Nathan W. Morris', attributed: true),
  Quote('Compound interest is the eighth wonder of the world.', 'Albert Einstein — though there is no record he ever said it', attributed: true),
  Quote('An investment in knowledge pays the best interest.', 'Benjamin Franklin', attributed: true),
  Quote('A penny saved is a penny earned.', 'English proverb, popularised by Benjamin Franklin'),
  Quote('The rich rule over the poor, and the borrower is servant to the lender.', 'Proverbs 22:7'),
  Quote('Go to the ant: she prepares her bread in summer and gathers her food at harvest.', 'Proverbs 6:6–8'),
  Quote('The best time to plant a tree was 20 years ago. The second-best time is now.', 'Proverb'),
  Quote('He who buys what he does not need steals from himself.', 'Swedish proverb'),
  Quote('The art is not in making money, but in keeping it.', 'Proverb'),
  Quote('Money grows on the tree of persistence.', 'Japanese proverb'),
  Quote('Debt is the slavery of the free.', 'Publilius Syrus', attributed: true),
  Quote('Frugality includes all the other virtues.', 'Cicero', attributed: true),
  Quote('Do what you can, with what you have, where you are.', 'Theodore Roosevelt', attributed: true),
  Quote('Know what you own, and know why you own it.', 'Peter Lynch', attributed: true),
  Quote('Formal education will make you a living; self-education will make you a fortune.', 'Jim Rohn', attributed: true),
  Quote('Spend less than you earn, and put the difference to work.', 'Common advice'),
  Quote('Small amounts saved every month beat large amounts saved someday.', 'Common advice'),
  Quote('A salary is what you earn. Savings are what you keep.', 'Common advice'),
  Quote('If you can’t buy it twice, you can’t afford it.', 'Common advice'),
  Quote('Wait a day before you buy what you want; buy today only what you need.', 'The 24-hour rule'),
  Quote('Pay yourself first: on payday, your savings get paid before anyone else.', 'Common advice'),
  Quote('थोपा थोपा मिली घडा भरिन्छ।', 'Nepali proverb', translation: 'Drop by drop, the pot fills.'),
  Quote('जति चादर, उति खुट्टा तन्काउनु।', 'Nepali proverb', translation: 'Stretch your legs only as far as your blanket — live within your means.'),
  Quote('आफ्नो हात जगन्नाथ।', 'Nepali proverb', translation: 'Your own hands are your best help — rely on yourself.'),
  Quote('धैर्यको फल मीठो हुन्छ।', 'Nepali proverb', translation: 'The fruit of patience is sweet.'),
  Quote('लोभले लाभ, लाभले विलाप।', 'Nepali proverb', translation: 'Greed brings gain, and that gain brings grief.'),
  Quote('पैसाले पैसा कमाउँछ।', 'Nepali saying', translation: 'Money makes money — let your savings work.'),
];
