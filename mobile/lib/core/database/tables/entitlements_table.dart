import 'package:drift/drift.dart';

class Entitlements extends Table {
  IntColumn get id => integer().autoIncrement()();
  BoolColumn get proLifetime =>
      boolean().withDefault(const Constant(false))();
  TextColumn get purchasedPacks =>
      text().withDefault(const Constant('[]'))(); // JSON array of pack IDs
  IntColumn get photoOverlayCount =>
      integer().withDefault(const Constant(0))();
}
