import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/records.dart';
import '../../finance/finance.dart';
import '../../store/data_providers.dart';
import '../icons/paisa_icon.dart';
import '../icons/paisa_icons.dart';
import '../screens/settings/config_item_sheet.dart';
import '../theme.dart';
import '../tokens.dart';
import '../typography.dart';

const _addNew = '\u0000add';
const _none = '\u0000none';

/// "Received from" for money in, "Paid to" for money out.
String partyLabel(TxType type) => type == TxType.expense ? 'Paid to' : 'Received from';

/// The party in [parties] whose name appears in [text] (an SMS merchant or
/// remark), so a known payer or payee is picked without asking.
String? guessParty(Iterable<ConfigItem> parties, String text) {
  final t = text.toLowerCase();
  for (final p in parties) {
    if (p.active && p.name.trim().length >= 2 && t.contains(p.name.trim().toLowerCase())) return p.id;
  }
  return null;
}

/// Drop-down of the configurable Parties list (Settings → Parties), with
/// "Add new…" at the end so a new payer or payee can be added on the spot.
class PartyField extends ConsumerWidget {
  const PartyField({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final all = ref.watch(configListProvider(ConfigList.parties)).value ?? const <ConfigItem>[];
    // A disabled party stays visible while it is the one selected.
    final parties = [
      for (final p in all)
        if (p.active || p.id == value) p,
    ];
    final selected = parties.any((p) => p.id == value) ? value! : _none;
    final style = PaisaText.body.copyWith(fontSize: 16, color: c.ink);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(label, style: PaisaText.label.copyWith(color: c.ink2)),
        ),
        const SizedBox(height: 6),
        Container(
          height: PaisaSize.inputHeight,
          padding: const EdgeInsets.only(left: 14, right: 10),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(PaisaSize.radiusInput),
            border: Border.all(color: c.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: const ValueKey('party-dropdown'),
              value: selected,
              isExpanded: true,
              dropdownColor: c.surface2,
              borderRadius: BorderRadius.circular(PaisaSize.radiusInput),
              icon: PaisaIcon(PaisaIcons.chevD, size: 19, color: c.ink3),
              style: style,
              items: [
                DropdownMenuItem(
                  value: _none,
                  child: Text('Not set', style: style.copyWith(color: c.ink3)),
                ),
                for (final p in parties)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text(p.name, overflow: TextOverflow.ellipsis),
                  ),
                DropdownMenuItem(
                  value: _addNew,
                  child: Row(
                    children: [
                      PaisaIcon(PaisaIcons.plus, size: 18, color: c.primary),
                      const SizedBox(width: 8),
                      Text('Add new…', style: style.copyWith(color: c.primary)),
                    ],
                  ),
                ),
              ],
              onChanged: (v) async {
                if (v == _addNew) {
                  final id = await showConfigItemSheet(context, ConfigList.parties, title: 'New party');
                  if (id != null) onChanged(id);
                } else {
                  onChanged(v == _none ? null : v);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
