import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/cards_table.dart';
import 'tables/purchases_table.dart';
import 'tables/entitlements_table.dart';
import 'tables/custom_photo_templates_table.dart';
import 'daos/cards_dao.dart';
import 'daos/purchases_dao.dart';
import 'daos/entitlements_dao.dart';
import 'daos/custom_photo_templates_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Cards, Purchases, Entitlements, CustomPhotoTemplates],
  daos: [CardsDao, PurchasesDao, EntitlementsDao, CustomPhotoTemplatesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // v1 → v2: custom card cover photo support
        if (from < 2) {
          await m.addColumn(cards, cards.customCoverImagePath);
        }
        // v2 → v3: photo pan/zoom positioning
        if (from < 3) {
          await m.addColumn(cards, cards.coverImageOffsetX);
          await m.addColumn(cards, cards.coverImageOffsetY);
          await m.addColumn(cards, cards.coverImageScale);
        }
        // v3 → v4: custom photo templates table
        if (from < 4) {
          await m.createTable(customPhotoTemplates);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'barcode_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
