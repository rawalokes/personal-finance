import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/records.dart';
import '../../../data/repos/catalog_repo.dart';
import '../../../store/data_providers.dart';
import '../../components/buttons.dart';
import '../../components/sheet.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';

class _ItemForm extends ChangeNotifier {
  _ItemForm(ConfigItem? item)
    : name = TextEditingController(text: item?.name ?? ''),
      description = TextEditingController(text: item?.description ?? '');

  final TextEditingController name, description;
  String? error;
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

/// Adds an entry to [listKey], or edits [item]. Returns the entry's id, or
/// null if the user cancelled.
Future<String?> showConfigItemSheet(BuildContext context, String listKey, {ConfigItem? item, String? title}) =>
    showPaisaFormSheet<String, _ItemForm>(
      context,
      title: title ?? (item == null ? 'New entry' : 'Edit ${item.name}'),
      create: () => _ItemForm(item),
      body: (ctx, f) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaisaTextField(label: 'Name', controller: f.name, errorText: f.error, autofocus: item == null),
          const SizedBox(height: 14),
          PaisaTextField(label: 'Description', controller: f.description, hint: 'Optional'),
        ],
      ),
      footer: (ctx, f) => Consumer(
        builder: (ctx, ref, _) => Row(
          children: [
            Expanded(
              child: PaisaButton(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.of(ctx).pop()),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PaisaButton(
                label: item == null ? 'Add' : 'Save',
                onPressed: () async {
                  final name = f.name.text.trim();
                  if (name.isEmpty) {
                    f.setError('Enter a name');
                    return;
                  }
                  final repo = ref.read(catalogRepoProvider);
                  final String id;
                  try {
                    if (item == null) {
                      id = await repo.addConfigItem(listKey, name, f.description.text);
                    } else {
                      await repo.editConfigItem(item.id, name, f.description.text);
                      id = item.id;
                    }
                  } on DuplicateName {
                    f.setError('$name is already in the list');
                    return;
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop(id);
                  ref.read(toastProvider.notifier).show(item == null ? '$name added' : '$name saved');
                },
              ),
            ),
          ],
        ),
      ),
    );
