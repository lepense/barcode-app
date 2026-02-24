import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/purchases_table.dart';

part 'purchases_dao.g.dart';

@DriftAccessor(tables: [Purchases])
class PurchasesDao extends DatabaseAccessor<AppDatabase>
    with _$PurchasesDaoMixin {
  PurchasesDao(super.db);

  Future<List<Purchase>> getAllPurchases() => select(purchases).get();

  Stream<List<Purchase>> watchAllPurchases() => select(purchases).watch();

  Future<int> insertPurchase(PurchasesCompanion entry) =>
      into(purchases).insert(entry);

  /// Returns null if transactionId doesn't exist yet (idempotency check)
  Future<Purchase?> findByTransactionId(String txnId) =>
      (select(purchases)..where((p) => p.transactionId.equals(txnId)))
          .getSingleOrNull();

  Future<bool> updatePurchase(Purchase entry) =>
      update(purchases).replace(entry);
}
