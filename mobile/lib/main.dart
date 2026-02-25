import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase will be configured via FlutterFire CLI (generates firebase_options.dart)
  // For now, initialize with default options — will fail until Firebase project is set up
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  runApp(
    const ProviderScope(
      child: BarcodeApp(),
    ),
  );
}
