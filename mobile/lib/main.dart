import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app/app.dart';
import 'core/services/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase will be configured via FlutterFire CLI (generates firebase_options.dart)
  // For now, initialize with default options — will fail until Firebase project is set up
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  // Home screen widget plugin init (iOS App Group ID).
  await WidgetService.init();

  // google_sign_in v7: initialize() must be called exactly once before authenticate().
  // serverClientId is the web OAuth client (type 3) from google-services.json —
  // required on Android to receive an idToken that Firebase can verify.
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '139663117667-d06bou8c3kav0lis4m2akjhq7dm4ln6c.apps.googleusercontent.com',
  );

  runApp(
    const ProviderScope(
      child: BarcodeApp(),
    ),
  );
}
