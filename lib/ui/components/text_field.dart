import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../finance/calendar.dart';
import '../../finance/dates.dart';
import '../../store/ui_state.dart';
import '../icons/paisa_icon.dart';
import 'buttons.dart';
import '../icons/paisa_icons.dart';
import '../theme.dart';
import '../tokens.dart';
import '../typography.dart';

/// Labelled text input (`.fld` + `.inp`). [big] is the 64 px amount field
/// (`.inp.big`). [errorText] turns the border red and shows the message
/// below (`.errt`).
class PaisaTextField extends StatelessWidget {
  const PaisaTextField({
    super.key,
    required this.label,
    required this.controller,
    this.onChanged,
    this.hint,
    this.helper,
    this.errorText,
    this.big = false,
    this.keyboardType,
    this.prefixIcon,
    this.autofocus = false,
    this.showLabel = true,
    this.obscure = false,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? hint;

  /// Grey hint under the field, e.g. "Never store the full number".
  final String? helper;
  final String? errorText;
  final bool big;
  final TextInputType? keyboardType;
  final String? prefixIcon;
  final bool autofocus;

  /// False when the label is only for screen readers (e.g. the search box).
  final bool showLabel;

  /// Hide what is typed (PINs).
  final bool obscure;

  /// More than 1 for longer text such as a pasted SMS.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasError = errorText != null;
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(PaisaSize.radiusInput),
          borderSide: BorderSide(color: color, width: width),
        );
    final textStyle = big
        ? PaisaText.numeric(PaisaText.h1.copyWith(fontSize: 28, fontVariations: const [FontVariation('wght', 750)]))
        : PaisaText.body.copyWith(fontSize: 16);
    final field = Semantics(
      label: label,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        keyboardType: keyboardType,
        obscureText: obscure,
        maxLines: maxLines,
        minLines: 1,
        style: textStyle.copyWith(color: c.ink),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: c.surface,
          hintText: hint,
          hintStyle: textStyle.copyWith(color: c.ink3),
          constraints: BoxConstraints(minHeight: big ? PaisaSize.inputBigHeight : PaisaSize.inputHeight),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: big ? 16 : 14),
          prefixIcon: prefixIcon == null
              ? null
              : Padding(padding: const EdgeInsets.only(left: 14, right: 10), child: PaisaIcon(prefixIcon!, size: 19, color: c.ink3)),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          enabledBorder: border(hasError ? c.red : c.line),
          focusedBorder: border(hasError ? c.red : c.primary, 2),
        ),
      ),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      if (showLabel) ...[
        ExcludeSemantics(child: Text(label, style: PaisaText.label.copyWith(color: c.ink2))),
        const SizedBox(height: 6),
      ],
      field,
      if (hasError) ...[
        const SizedBox(height: 6),
        Semantics(
          liveRegion: true,
          child: Text(
            errorText!,
            style: PaisaText.hint.copyWith(color: c.red, fontVariations: const [FontVariation('wght', 650)]),
          ),
        ),
      ] else if (helper != null) ...[
        const SizedBox(height: 6),
        Text(helper!, style: PaisaText.hint.copyWith(color: c.ink3)),
      ],
    ]);
  }
}

/// A date input that opens the platform date picker. Shows '14 Oct 2026'.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final IsoDate value;
  final ValueChanged<IsoDate> onChanged;

  Future<void> _pick(BuildContext context) async {
    final d = parseIsoDate(value);
    final initial = DateTime(d.year, d.month, d.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(initial.year + 5, 12, 31),
    );
    if (picked != null) onChanged(toIsoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
      final cal = ref.watch(monthCalendarProvider);
      final text = cal is AdCalendar ? longDate(value) : '${cal.longDate(value)} · ${longDate(value)}';
      return _build(context, text);
    });
  }

  Widget _build(BuildContext context, String text) {
    final c = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      ExcludeSemantics(child: Text(label, style: PaisaText.label.copyWith(color: c.ink2))),
      const SizedBox(height: 6),
      Semantics(
        button: true,
        label: '$label, $text',
        excludeSemantics: true,
        child: Material(
          color: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PaisaSize.radiusInput),
            side: BorderSide(color: c.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(PaisaSize.radiusInput),
            onTap: () => _pick(context),
            child: SizedBox(
              height: PaisaSize.inputHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  Expanded(child: Text(text, style: PaisaText.body.copyWith(fontSize: 16, color: c.ink))),
                  PaisaIcon(PaisaIcons.calendar, size: 19, color: c.ink3),
                ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

/// A date the user may leave empty ("No date"), e.g. a goal's target date.
class OptionalDateField extends StatelessWidget {
  const OptionalDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.initialPick,
  });

  final String label;
  final IsoDate? value;
  final ValueChanged<IsoDate?> onChanged;

  /// Where the picker opens when nothing is set yet.
  final IsoDate initialPick;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v != null) {
      return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: DateField(label: label, value: v, onChanged: onChanged)),
        PaisaIconButton(icon: PaisaIcons.close, label: 'Clear $label', onPressed: () => onChanged(null)),
      ]);
    }
    final c = context.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      ExcludeSemantics(child: Text(label, style: PaisaText.label.copyWith(color: c.ink2))),
      const SizedBox(height: 6),
      Align(
        alignment: Alignment.centerLeft,
        child: PaisaButton(
          label: 'No date · set one',
          icon: PaisaIcons.calendar,
          variant: ButtonVariant.outline,
          small: true,
          onPressed: () => onChanged(initialPick),
        ),
      ),
    ]);
  }
}
