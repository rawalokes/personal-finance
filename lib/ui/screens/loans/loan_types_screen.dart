import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repos/catalog_repo.dart';
import '../../../finance/finance.dart';
import '../../../store/data_providers.dart';
import '../../components/async_view.dart';
import '../../components/buttons.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/sheet.dart';
import '../../components/surfaces.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../icons/paisa_icons.dart';
import '../../loans/loan_presentation.dart';
import '../../shell/detail_page.dart';
import '../../theme.dart';
import '../../typography.dart';

final _typesDataProvider = FutureProvider<(List<LoanType>, List<Loan>)>(
  (ref) async => (await ref.watch(loanTypesProvider.future), await ref.watch(loansProvider.future)),
);

/// Loan types: editable examples, each holding any number of loans.
class LoanTypesScreen extends ConsumerWidget {
  const LoanTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DetailPage(
      title: 'Loan types',
      actions: [PaisaLink(label: 'New type', onPressed: () => showLoanTypeSheet(context, null))],
      body: AsyncView(
        value: ref.watch(_typesDataProvider),
        data: (d) {
          final (types, loans) = d;
          final c = context.colors;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), children: [
            Text(
              'Starting examples you can rename, disable or extend. Each type can hold any number of individual loans.',
              style: PaisaText.sub.copyWith(color: c.ink3),
            ),
            const SizedBox(height: 12),
            PaisaListCard(children: [
              for (final t in types)
                Opacity(
                  opacity: t.active ? 1 : 0.6,
                  child: ListRow(
                    title: t.name,
                    subtitle: '${_count(loans, t.id)} · ${methodLabel(t.defaultMethod)}',
                    leading: IconWell(icon: PaisaIcons.named(t.icon), tone: t.active ? Tone.amber : Tone.neutral),
                    onTap: () => showLoanTypeSheet(context, t),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      PaisaIconButton(
                        icon: PaisaIcons.plus,
                        label: 'Add a ${t.name.toLowerCase()}',
                        onPressed: t.active ? () => context.push('/loans/new?type=${t.id}') : null,
                      ),
                      PaisaToggle(
                        value: t.active,
                        label: '${t.active ? 'Disable' : 'Enable'} ${t.name}',
                        onChanged: (on) async {
                          await ref.read(catalogRepoProvider).saveLoanType(LoanType(
                                id: t.id, name: t.name, description: t.description, icon: t.icon,
                                defaultMethod: t.defaultMethod, active: on,
                              ));
                          ref.read(toastProvider.notifier).show('${t.name} ${on ? 'enabled' : 'disabled'}');
                        },
                      ),
                    ]),
                  ),
                ),
            ]),
          ]);
        },
      ),
    );
  }

  static String _count(List<Loan> loans, String typeId) {
    final n = loans.where((l) => l.loanTypeId == typeId).length;
    return n == 0 ? 'No loans' : '$n ${n == 1 ? 'loan' : 'loans'}';
  }
}

class _TypeForm extends ChangeNotifier {
  _TypeForm(LoanType? t)
      : name = TextEditingController(text: t?.name ?? ''),
        description = TextEditingController(text: t?.description ?? ''),
        method = t?.defaultMethod ?? InterestMethod.reducing;
  final TextEditingController name;
  final TextEditingController description;
  InterestMethod method;
  String? error;

  void setMethod(InterestMethod m) {
    method = m;
    notifyListeners();
  }

  void setError(String? e) {
    error = e;
    notifyListeners();
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }
}

/// New (null) or edit a loan type.
Future<void> showLoanTypeSheet(BuildContext context, LoanType? type) => showPaisaFormSheet<void, _TypeForm>(
      context,
      title: type == null ? 'New loan type' : 'Edit loan type',
      create: () => _TypeForm(type),
      body: (ctx, f) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PaisaTextField(label: 'Name', controller: f.name, hint: 'e.g. Gold Loan', errorText: f.error),
        const SizedBox(height: 14),
        PaisaTextField(label: 'Description', controller: f.description, hint: 'Optional'),
        const SizedBox(height: 14),
        FieldGroup(
          label: 'Default interest method',
          child: ChipWrap(children: [
            for (final m in InterestMethod.values)
              PaisaChip(label: methodLabel(m), selected: f.method == m, onTap: () => f.setMethod(m)),
          ]),
        ),
      ]),
      footer: (ctx, f) => Consumer(
        builder: (ctx, ref, _) => Row(children: [
          Expanded(child: PaisaButton(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.of(ctx).pop())),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PaisaButton(
              label: 'Save',
              onPressed: () async {
                final name = f.name.text.trim();
                if (name.isEmpty) {
                  f.setError('Enter a name');
                  return;
                }
                try {
                  await ref.read(catalogRepoProvider).saveLoanType(LoanType(
                        id: type?.id ?? '',
                        name: name,
                        description: f.description.text.trim().isEmpty ? null : f.description.text.trim(),
                        icon: type?.icon ?? 'rupee',
                        defaultMethod: f.method,
                        active: type?.active ?? true,
                      ));
                } on DuplicateName {
                  f.setError('A loan type with this name already exists');
                  return;
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
                ref.read(toastProvider.notifier).show(
                      type == null ? '$name added — you can now add loans under it' : 'Loan type updated',
                    );
              },
            ),
          ),
        ]),
      ),
    );
