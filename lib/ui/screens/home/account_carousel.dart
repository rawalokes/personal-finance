import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/records.dart';
import '../../../finance/finance.dart';
import '../../accounts/account_presentation.dart';
import '../../components/money_text.dart';
import '../../icons/paisa_icon.dart';
import '../../icons/paisa_icons.dart';
import '../../theme.dart';
import '../../typography.dart';
import '../accounts/add_account_sheet.dart';

/// Home's horizontally scrolling account cards (spec §7 "Home account
/// cards", acceptance test 15): touch swipe, mouse drag and mouse wheel all
/// scroll it, and the last card opens Add account.
class AccountCarousel extends StatefulWidget {
  const AccountCarousel({super.key, required this.accounts, required this.types});

  /// Already filtered: non-archived, non-locked.
  final List<Account> accounts;
  final List<ConfigItem> types;

  @override
  State<AccountCarousel> createState() => _AccountCarouselState();
}

class _AccountCarouselState extends State<AccountCarousel> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// A vertical wheel scrolls the cards sideways while they can still move
  /// that way; at either end the page scrolls instead (as in the mockup).
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final dy = event.scrollDelta.dy;
    if (dy.abs() <= event.scrollDelta.dx.abs()) return;
    final p = _controller.position;
    final canMove = (dy > 0 && p.pixels < p.maxScrollExtent) || (dy < 0 && p.pixels > p.minScrollExtent);
    if (!canMove) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      _controller.jumpTo((p.pixels + dy).clamp(p.minScrollExtent, p.maxScrollExtent));
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.accounts;
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad, PointerDeviceKind.stylus},
        ),
        child: SizedBox(
          height: 124,
          child: Semantics(
            label: 'Accounts',
            child: ListView.separated(
              key: const Key('account-carousel'),
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => i == items.length
                  ? const _AddAccountCard()
                  : _AccountCard(account: items[i], typeLabel: accountTypeLabel(items[i], widget.types), hero: i == 0),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.typeLabel, required this.hero});
  final Account account;
  final String typeLabel;

  /// The first card is wider and uses the blue hero gradient.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = account;
    final owed = isOwed(a.group, a.balance);
    final sub = hero ? c.heroCardSub : c.ink3;
    return SizedBox(
      width: hero ? 210 : 160,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: hero ? null : c.surface,
            gradient: hero
                ? LinearGradient(colors: [c.heroCardStart, c.heroCardEnd], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            borderRadius: BorderRadius.circular(22),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => context.push('/accounts/${a.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Expanded(
                    child: Text(a.shortName, maxLines: 1, overflow: TextOverflow.ellipsis, style: PaisaText.sub.copyWith(color: sub)),
                  ),
                  if (a.autoUpdateFromSms)
                    Text('AUTO', style: PaisaText.tag.copyWith(fontSize: 11, color: c.primary)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Cards have a fixed width: shrink a long amount rather than cut it.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: MoneyText(
                      shownBalance(a.group, a.balance),
                      sign: owedSign(a.group, a.balance),
                      style: PaisaText.h2.copyWith(fontSize: 21, color: c.ink),
                    ),
                  ),
                  Text(
                    owed
                        ? '$typeLabel · owed'
                        : isInCredit(a.group, a.balance)
                            ? '$typeLabel · in credit'
                            : typeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PaisaText.hint.copyWith(fontSize: 12, color: sub),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddAccountCard extends StatelessWidget {
  const _AddAccountCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 132,
      child: CustomPaint(
        painter: _DashedBorder(color: c.line),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => showAddAccountSheet(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: PaisaIcon(PaisaIcons.plus, size: 19, color: c.ink2),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add eSewa, Khalti or bank',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PaisaText.buttonSmall.copyWith(fontSize: 13, color: c.ink2),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// 1.5 px dashed rounded outline (`border: 1.5px dashed var(--line)`).
class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22)).deflate(0.75);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
