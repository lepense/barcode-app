import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';

/// Streams all saved photo templates, newest first.
final customPhotoTemplatesProvider =
    StreamProvider<List<CustomPhotoTemplate>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.customPhotoTemplatesDao.watchAll();
});
