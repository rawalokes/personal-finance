import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/settings_models.dart';
import '../../../store/app_lock.dart';
import '../../../store/data_providers.dart';
import '../../../store/ui_state.dart';
import '../../components/buttons.dart';
import '../../components/indicators.dart';
import '../../components/inputs.dart';
import '../../components/layout.dart';
import '../../components/sheet.dart';
import '../../components/text_field.dart';
import '../../components/toast.dart';
import '../../components/tone.dart';
import '../../theme.dart';
import '../../typography.dart';

/// Hands a finished export to the user (Android share sheet: save to Files,
/// Drive, email…). Tests capture it instead.
typedef Exporter = Future<void> Function(String fileName, String content, String mimeType);

final exporterProvider = Provider<Exporter>((ref) => (fileName, content, mimeType) async {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: mimeType)], subject: fileName));
    });

enum _Format { csv, json }

class _ExportForm extends ChangeNotifier {
  _Format format = _Format.csv;
  bool busy = false;
  void set(_Format f) {
    format = f;
    notifyListeners();
  }

  void setBusy(bool b) {
    busy = b;
    notifyListeners();
  }
}

/// Export: transactions as CSV, or everything as a JSON backup. Secrets
/// (AI key, PIN) are never included.
Future<void> showExportSheet(BuildContext context) => showPaisaFormSheet<void, _ExportForm>(
      context,
      title: 'Export data',
      create: _ExportForm.new,
      body: (ctx, f) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FieldGroup(
          label: 'Format',
          child: ChipWrap(children: [
            PaisaChip(label: 'CSV (transactions)', selected: f.format == _Format.csv, onTap: () => f.set(_Format.csv)),
            PaisaChip(label: 'JSON backup', selected: f.format == _Format.json, onTap: () => f.set(_Format.json)),
          ]),
        ),
        const SizedBox(height: 14),
        const Note(
          'Exports stay on your phone until you choose where to send them. Your AI key and PIN are never included.',
          tone: Tone.blue,
        ),
      ]),
      footer: (ctx, f) => Consumer(
        builder: (ctx, ref, _) => Row(children: [
          Expanded(child: PaisaButton(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.of(ctx).pop())),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PaisaButton(
              label: f.busy ? 'Preparing…' : 'Export',
              onPressed: f.busy
                  ? null
                  : () async {
                      f.setBusy(true);
                      final data = ref.read(dataRepoProvider);
                      final today = ref.read(clockProvider).today();
                      final toast = ref.read(toastProvider.notifier);
                      try {
                        if (f.format == _Format.csv) {
                          await ref.read(exporterProvider)(
                            'paisa-transactions-$today.csv',
                            await data.exportTransactionsCsv(),
                            'text/csv',
                          );
                        } else {
                          await ref.read(exporterProvider)('paisa-backup-$today.json', await data.exportJson(), 'application/json');
                        }
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        toast.show('Export ready — choose where to save or share it');
                      } catch (_) {
                        if (ctx.mounted) f.setBusy(false);
                        toast.show('Couldn’t prepare the export');
                      }
                    },
            ),
          ),
        ]),
      ),
    );

class _DeleteForm extends ChangeNotifier {
  _DeleteForm() {
    confirm.addListener(notifyListeners);
  }
  final confirm = TextEditingController();
  bool busy = false;
  bool get ready => confirm.text.trim() == 'DELETE' && !busy;
  void setBusy(bool b) {
    busy = b;
    notifyListeners();
  }

  @override
  void dispose() {
    confirm.dispose();
    super.dispose();
  }
}

/// "Delete all data" with typed confirmation (spec §10): every account,
/// transaction, loan, goal and setting, plus the AI key and PIN. Leaves a
/// clean install.
Future<void> showDeleteAllSheet(BuildContext context) => showPaisaFormSheet<void, _DeleteForm>(
      context,
      title: 'Delete all data',
      create: _DeleteForm.new,
      body: (ctx, f) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          'This erases every account, transaction, loan, goal and setting on this phone, and removes your AI key and PIN. '
          'It cannot be undone. Export a backup first if you might need it.',
          style: PaisaText.sub.copyWith(color: ctx.colors.ink2),
        ),
        const SizedBox(height: 14),
        PaisaTextField(label: 'Type DELETE to confirm', controller: f.confirm),
      ]),
      footer: (ctx, f) => Consumer(
        builder: (ctx, ref, _) => Row(children: [
          Expanded(child: PaisaButton(label: 'Cancel', variant: ButtonVariant.outline, onPressed: () => Navigator.of(ctx).pop())),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: PaisaButton(
              label: 'Delete everything',
              variant: ButtonVariant.danger,
              onPressed: !f.ready
                  ? null
                  : () async {
                      f.setBusy(true);
                      final router = GoRouter.of(ctx);
                      await ref.read(dataRepoProvider).deleteAllData();
                      await ref.read(secretStoreProvider).deleteAll();
                      ref.read(hideBalancesProvider.notifier).set(false);
                      ref.read(groupingProvider.notifier).set(const AppPrefs().grouping);
                      ref.read(calendarProvider.notifier).set(const AppPrefs().calendar);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      router.go('/home');
                      ref.read(toastProvider.notifier).show('All data deleted');
                    },
            ),
          ),
        ]),
      ),
    );
