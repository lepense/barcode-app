import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/entitlements_table.dart';

part 'entitlements_dao.g.dart';

@DriftAccessor(tables: [Entitlements])
class EntitlementsDao extends DatabaseAccessor<AppDatabase>
    with _$EntitlementsDaoMixin {
  EntitlementsDao(super.db);

  /// Returns the single entitlements row, or null if none exists yet.
  Future<Entitlement?> getCurrent() =>
      (select(entitlements)..limit(1)).getSingleOrNull();

  /// Streams the entitlements row — rebuilds UI whenever it changes.
  Stream<Entitlement?> watchCurrent() =>
      (select(entitlements)..limit(1)).watchSingleOrNull();

  /// Inserts the first entitlements row (call once at onboarding).
  Future<int> init() => into(entitlements).insert(
        const EntitlementsCompanion(),
        mode: InsertMode.insertOrIgnore,
      );

  Future<void> setProLifetime() =>
      (update(entitlements)..where((_) => const Constant(true)))
          .write(const EntitlementsCompanion(proLifetime: Value(true)));

  Future<void> addPurchasedPack(String packJson) =>
      (update(entitlements)..where((_) => const Constant(true)))
          .write(EntitlementsCompanion(purchasedPacks: Value(packJson)));
}
