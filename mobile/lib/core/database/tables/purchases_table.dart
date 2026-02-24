import 'package:drift/drift.dart';

class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sku => text()();
  TextColumn get platform => text()();
  TextColumn get transactionId => text().unique()();
  DateTimeColumn get purchaseDate => dateTime()();
  TextColumn get status => text()(); // active, refunded, expired
}
