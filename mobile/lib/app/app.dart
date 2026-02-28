import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/splash/splash_screen.dart';
import 'router.dart';
import 'theme.dart';

class BarcodeApp extends ConsumerStatefulWidget {
  const BarcodeApp({super.key});

  @override
  ConsumerState<BarcodeApp> createState() => _BarcodeAppState();
}

class _BarcodeAppState extends ConsumerState<BarcodeApp> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Barcode App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      // The builder sits on top of the router; while splash is running it
      // covers the whole screen.  When the animation finishes we reveal the
      // underlying router content seamlessly (same MaterialApp context →
      // no widget-tree rebuild / flash).
      builder: (context, child) {
        if (!_splashDone) {
          return SplashScreen(
            onComplete: () => setState(() => _splashDone = true),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
