import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../icons/paisa_icons.dart';
import 'empty_state.dart';
import 'skeleton.dart';
import 'tone.dart';

/// Loading skeleton, friendly error, or [data] for an [AsyncValue]
/// (spec §7: loading and error states everywhere). Refreshes keep showing
/// the previous data instead of flashing the skeleton.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.data});

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const _LoadingList(),
      error: (e, _) => const EmptyState(
        icon: PaisaIcons.alert,
        tone: Tone.red,
        title: 'Couldn’t load your data',
        body: 'Something went wrong reading the database. Close and reopen Paisa to try again.',
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Skeleton(width: 140, height: 14),
        SizedBox(height: 12),
        Skeleton(height: 48, radius: 14),
        SizedBox(height: 12),
        Skeleton(height: 64, radius: 22),
        SizedBox(height: 12),
        Skeleton(height: 64, radius: 22),
      ]),
    );
  }
}
