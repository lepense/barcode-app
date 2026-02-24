import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class BarcodeApp extends StatelessWidget {
  const BarcodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Barcode App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
