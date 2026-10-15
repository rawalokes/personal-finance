import 'package:flutter/material.dart';

import '../icons/paisa_icons.dart';
import '../theme.dart';
import '../tokens.dart';
import '../typography.dart';
import 'buttons.dart';

/// Opens a bottom sheet in the mockup style: grab handle, title + close,
/// scrolling body (gap 14) and optional footer row with a top hairline.
Future<T?> showPaisaSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  WidgetBuilder? footerBuilder,
}) =>
    _showSheet<T>(
      context,
      (ctx) => PaisaSheetFrame(title: title, body: builder(ctx), footer: footerBuilder?.call(ctx)),
    );

/// A sheet whose body and footer share one form object. [create] runs once
/// when the sheet opens; the form is disposed only after the sheet has fully
/// closed (not when the future completes, which is before the exit
/// animation ends). Body and footer rebuild when the form notifies.
Future<T?> showPaisaFormSheet<T, F extends ChangeNotifier>(
  BuildContext context, {
  required String title,
  required F Function() create,
  required Widget Function(BuildContext context, F form) body,
  Widget Function(BuildContext context, F form)? footer,
}) =>
    _showSheet<T>(context, (ctx) => _FormSheet<F>(title: title, create: create, body: body, footer: footer));

Future<T?> _showSheet<T>(BuildContext context, WidgetBuilder builder) {
  final c = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: c.surface,
    barrierColor: c.scrim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(PaisaSize.radiusSheet)),
    ),
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    builder: builder,
  );
}

class _FormSheet<F extends ChangeNotifier> extends StatefulWidget {
  const _FormSheet({required this.title, required this.create, required this.body, this.footer});

  final String title;
  final F Function() create;
  final Widget Function(BuildContext, F) body;
  final Widget Function(BuildContext, F)? footer;

  @override
  State<_FormSheet<F>> createState() => _FormSheetState<F>();
}

class _FormSheetState<F extends ChangeNotifier> extends State<_FormSheet<F>> {
  late final F form = widget.create();

  @override
  void dispose() {
    form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: form,
      builder: (context, _) => PaisaSheetFrame(
        title: widget.title,
        body: widget.body(context, form),
        footer: widget.footer?.call(context, form),
      ),
    );
  }
}

class PaisaSheetFrame extends StatelessWidget {
  const PaisaSheetFrame({super.key, required this.title, required this.body, this.footer});

  final String title;
  final Widget body;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 2),
              decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(9)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            child: Row(children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: PaisaText.h2.copyWith(color: c.ink)),
                ),
              ),
              PaisaIconButton(icon: PaisaIcons.close, label: 'Close', onPressed: () => Navigator.of(context).pop()),
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: body,
            ),
          ),
          if (footer != null)
            DecoratedBox(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
              child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), child: footer),
            ),
        ],
      ),
    );
  }
}
