import 'package:flutter_test/flutter_test.dart';
import 'package:paisa/content/lessons.dart';
import 'package:paisa/content/quotes.dart';

void main() {
  test('about 20 lessons with unique ids, real text and https sources', () {
    expect(kLessons.length, greaterThanOrEqualTo(20));
    expect(kLessons.map((l) => l.id).toSet(), hasLength(kLessons.length));
    for (final l in kLessons) {
      expect(l.title.trim(), isNotEmpty, reason: l.id);
      expect(l.body.split(RegExp(r'\s+')).length, greaterThan(60), reason: '${l.id} is a real lesson');
      expect(l.sources, isNotEmpty, reason: '${l.id} cites where it comes from');
      for (final s in l.sources) {
        expect(Uri.parse(s.url).scheme, 'https', reason: s.url);
      }
    }
    expect(LessonTopic.values.every((t) => kLessons.any((l) => l.topic == t)), isTrue);
  });

  test('every quote has an author; Nepali proverbs carry a translation', () {
    expect(kQuotes.length, greaterThanOrEqualTo(45));
    for (final q in kQuotes) {
      expect(q.text.trim(), isNotEmpty);
      expect(q.author.trim(), isNotEmpty);
      if (q.author.startsWith('Nepali')) expect(q.translation, isNotNull, reason: q.text);
    }
    expect(kQuotes.where((q) => q.attributed).first.byline, startsWith('attributed to '));
  });
}
