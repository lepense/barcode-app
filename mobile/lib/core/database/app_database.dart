import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/cards_table.dart';
import 'tables/purchases_table.dart';
import 'tables/entitlements_table.dart';
import 'daos/cards_dao.dart';
import 'daos/purchases_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Cards, Purchases, Entitlements],
  daos: [CardsDao, PurchasesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations go here
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
