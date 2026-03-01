import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/custom_photo_templates_table.dart';

part 'custom_photo_templates_dao.g.dart';

@DriftAccessor(tables: [CustomPhotoTemplates])
class CustomPhotoTemplatesDao extends DatabaseAccessor<AppDatabase>
    with _$CustomPhotoTemplatesDaoMixin {
  CustomPhotoTemplatesDao(super.db);

  /// Streams all templates ordered newest-first.
  Stream<List<CustomPhotoTemplate>> watchAll() =>
      (select(customPhotoTemplates)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Persists a new template and returns its generated ID.
  Future<int> insertTemplate(CustomPhotoTemplatesCompanion entry) =>
      into(customPhotoTemplates).insert(entry);

  /// Permanently removes a template row by its [id].
  Future<int> deleteTemplate(int id) =>
      (delete(customPhotoTemplates)..where((t) => t.id.equals(id))).go();
}
