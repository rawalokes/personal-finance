/// Reverses one change. Every repository write that the UI offers "Undo"
/// for returns one. It runs at most once: a second call (a double tap on
/// Undo, or a stale toast) does nothing, so a change is never reversed twice.
class UndoAction {
  UndoAction(this._run);

  /// An undo that does nothing (for changes that need no reversal).
  UndoAction.none() : _run = _noop;

  /// Runs [actions] last-first, as one undo.
  UndoAction.combine(List<UndoAction> actions)
      : _run = (() async {
          for (final a in actions.reversed) {
            await a();
          }
        });

  static Future<void> _noop() async {}

  final Future<void> Function() _run;
  bool _used = false;

  bool get isUsed => _used;

  Future<void> call() async {
    if (_used) return;
    _used = true;
    await _run();
  }
}
