import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/records.dart';
import '../../../integrations/gemini/schemas.dart';
import '../../../store/data_providers.dart';
import '../../../store/ui_state.dart';
import '../../ai/ai_panel.dart';
import '../../components/buttons.dart';
import '../../components/toast.dart';
import '../../theme.dart';
import '../../typography.dart';

/// "Suggest budgets with AI" on the Budgets segment (spec §9.4). Each
/// suggestion is applied only when the user taps Apply, and is audited as
/// `ai` (guardrail 2).
class AiBudgetSuggestionsButton extends StatelessWidget {
  const AiBudgetSuggestionsButton({super.key});

  @override
  Widget build(BuildContext context) => AiPanel<BudgetSuggestions>(
        label: 'Suggest budgets with AI',
        run: (ai) => ai.suggestBudgets(),
        result: (context, s) => _Suggestions(s),
      );
}

class _Suggestions extends ConsumerStatefulWidget {
  const _Suggestions(this.s);
  final BudgetSuggestions s;

  @override
  ConsumerState<_Suggestions> createState() => _SuggestionsState();
}

class _SuggestionsState extends ConsumerState<_Suggestions> {
  final _applied = <String>{};

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final money = ref.watch(moneyFormatProvider);
    final categories = {for (final x in ref.watch(categoriesProvider).value ?? const []) x.id: x};
    // Only categories that exist; the AI can't invent new ones.
    final items = [for (final s in widget.s.items) if (categories.containsKey(s.categoryId)) s];
    if (items.isEmpty) return Text('No changes suggested.', style: PaisaText.body.copyWith(color: c.ink2));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final (i, s) in items.indexed) ...[
        if (i > 0) Divider(height: 20, color: c.line),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${categories[s.categoryId]!.name} · ${money.npr(s.limit)}', style: PaisaText.h3.copyWith(color: c.ink)),
              const SizedBox(height: 2),
              Text(s.reason, style: PaisaText.sub.copyWith(color: c.ink3)),
            ]),
          ),
          const SizedBox(width: 10),
          PaisaButton(
            label: _applied.contains(s.categoryId) ? 'Applied' : 'Apply',
            small: true,
            variant: ButtonVariant.secondary,
            onPressed: _applied.contains(s.categoryId)
                ? null
                : () async {
                    await ref.read(catalogRepoProvider).setBudget(s.categoryId, s.limit, actor: AuditActor.ai);
                    if (!mounted) return;
                    setState(() => _applied.add(s.categoryId));
                    ref.read(toastProvider.notifier).show('${categories[s.categoryId]!.name} budget set to ${money.npr(s.limit)}');
                  },
          ),
        ]),
      ],
    ]);
  }
}
