import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/quotes.dart';
import '../data/clock.dart';
import '../data/repos/settings_repo.dart';
import '../finance/finance.dart';
import '../integrations/gemini/schemas.dart';
import 'ai.dart';
import 'data_providers.dart';

/// Which quote the Home card shows. Starts from today's date, so it changes
/// daily; pull-to-refresh or a tap moves to the next.
class QuoteIndex extends Notifier<int> {
  @override
  int build() => int.parse(ref.read(clockProvider).today().replaceAll('-', '')) % kQuotes.length;
  void next() => state = (state + 1) % kQuotes.length;
}

final quoteIndexProvider = NotifierProvider<QuoteIndex, int>(QuoteIndex.new);

final learnReadProvider = StreamProvider<Set<String>>((ref) => ref.watch(settingsRepoProvider).watchLearnRead());

Future<void> markLessonRead(SettingsRepository repo, String id) async => repo.saveLearnRead({...await repo.learnRead(), id});

final waitListProvider = StreamProvider<WaitList>((ref) => ref.watch(settingsRepoProvider).watchWaitList());

class WaitListController {
  WaitListController(this._repo, this._clock, this._newId);
  final SettingsRepository _repo;
  final Clock _clock;
  final String Function() _newId;

  Future<void> add({required String title, required Paisa amount, String? categoryId, String? accountId}) async {
    final w = await _repo.waitList();
    await _repo.saveWaitList(
      w.add(WaitItem(id: _newId(), title: title, amount: amount, addedAt: _clock.stamp(), categoryId: categoryId, accountId: accountId)),
      summary: 'Waiting 24 hours before buying $title',
    );
  }

  Future<void> addWish({required String title, required Paisa amount, int priority = 2, String? categoryId}) async {
    final w = await _repo.waitList();
    await _repo.saveWaitList(
      w.add(WaitItem(id: _newId(), title: title, amount: amount, addedAt: _clock.stamp(), categoryId: categoryId, wish: true, priority: priority)),
      summary: 'Added $title to the wish list',
    );
  }

  Future<void> setPriority(String id, int priority) async =>
      _repo.saveWaitList((await _repo.waitList()).setPriority(id, priority), summary: 'Changed a wish list priority');

  /// Not buying it after all: counted as saved. Returns the amount.
  Future<Paisa> skip(String id) async {
    final w = await _repo.waitList();
    final amount = w.items.where((i) => i.id == id).firstOrNull?.amount ?? 0;
    await _repo.saveWaitList(w.skip(id), summary: 'Decided not to buy after waiting');
    return amount;
  }

  Future<void> bought(String id) async => _repo.saveWaitList((await _repo.waitList()).bought(id), summary: 'Bought an item after waiting');
}

final waitListControllerProvider = Provider<WaitListController>(
  (ref) => WaitListController(ref.watch(settingsRepoProvider), ref.watch(clockProvider), ref.watch(idGenProvider)),
);

/// Today's AI lesson if one was already written (never makes a request).
final cachedAiLessonProvider = FutureProvider<AiLesson?>((ref) async {
  ref.watch(aiSettingsProvider);
  return ref.watch(aiServiceProvider).cachedLesson();
});
