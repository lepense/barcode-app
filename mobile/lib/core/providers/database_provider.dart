import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

/// Single AppDatabase instance shared across the app.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
