import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repos/sms_repo.dart';
import '../../router.dart';
import '../../store/data_providers.dart';
import '../../store/sms_sync.dart';
import '../components/toast.dart';
import '../feedback.dart';

/// Keeps the Transaction Inbox in step with the phone: on start and on
/// every return to Paisa it reads new SMS from the phone; while open it
/// takes live messages. Auto-saved ones get an undo toast (spec §6 step 7).
class SmsHost extends ConsumerStatefulWidget {
  const SmsHost({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SmsHost> createState() => _SmsHostState();
}

class _SmsHostState extends ConsumerState<SmsHost> with WidgetsBindingObserver {
  StreamSubscription<IngestResult>? _live;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _live = ref.read(smsSyncProvider).live().listen(_announce, onError: (Object _) {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _catchUp());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _live?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Back from Android settings: access may have been turned on or off.
    ref
      ..invalidate(smsAccessProvider)
      ..invalidate(notificationAccessProvider);
    _catchUp();
  }

  void _announce(IngestResult r) {
    final toast = ref.read(toastProvider.notifier);
    switch (r.outcome) {
      case IngestOutcome.autoSaved:
        final m = r.message!;
        final accounts = ref.read(accountsProvider).value ?? const [];
        final name = accounts.where((a) => a.id == m.accountId).firstOrNull?.shortName ?? m.institution;
        showUndoToast(toast, 'Auto-saved from SMS: ${m.direction.name == 'credit' ? '+' : '−'} ${toastNpr(ref, m.amount)} · $name', r.undo!);
      case IngestOutcome.inbox:
        toast.show('New transaction detected — needs your review');
      case IngestOutcome.ignored || IngestOutcome.alreadySeen:
        break;
    }
  }

  Future<void> _catchUp() async {
    if (_syncing || !mounted) return;
    _syncing = true;
    try {
      final sync = ref.read(smsSyncProvider);
      final report = await sync.catchUp();
      if (!mounted) return;
      final review = report.added - report.autoSaved;
      if (report.autoSaved == 1 && review == 0) {
        _announce(report.undo.single);
      } else if (report.added > 0) {
        ref.read(toastProvider.notifier).show(
              review > 0
                  ? '$review new transaction${review == 1 ? '' : 's'} need${review == 1 ? 's' : ''} your review'
                  : '${report.autoSaved} transactions saved from SMS',
            );
      }
      if (await sync.source.takeOpenInbox() && mounted) ref.read(routerProvider).go('/activity?seg=inbox');
    } on Object {
      // Reading SMS must never break the app; the inbox can be checked by hand.
    } finally {
      _syncing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
