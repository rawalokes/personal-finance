import 'package:flutter/material.dart';

import '../components/empty_state.dart';
import '../components/top_bar.dart';
import '../icons/paisa_icons.dart';

/// Stand-in for root screens until their plan builds them.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PaisaTopBar(title: title),
      const Expanded(
        child: Center(
          child: EmptyState(
            icon: PaisaIcons.layers,
            title: 'Nothing here yet',
            body: 'This screen is built in a later plan.',
          ),
        ),
      ),
    ]);
  }
}
