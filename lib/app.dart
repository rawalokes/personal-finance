import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'store/ui_state.dart';
import 'ui/components/toast.dart';
import 'ui/lock/lock_screen.dart';
import 'ui/sms/sms_host.dart';
import 'ui/theme.dart';
import 'ui/tokens.dart';

class PaisaApp extends ConsumerWidget {
  const PaisaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Paisa',
      debugShowCheckedModeBanner: false,
      theme: paisaTheme(PaisaColors.light),
      darkTheme: paisaTheme(PaisaColors.night),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => AppLockGate(
        child: PaisaToastHost(child: SmsHost(child: child ?? const SizedBox.shrink())),
      ),
    );
  }
}
