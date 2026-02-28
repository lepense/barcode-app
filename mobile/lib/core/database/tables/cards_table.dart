import 'package:drift/drift.dart';

class Cards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get merchantName => text()();
  TextColumn get barcodeType => text()();
  TextColumn get barcodeValueEncrypted => text()();
  TextColumn get coverDesignId => text().nullable()();
  /// Absolute path to a user-supplied cover image stored in the app docs dir.
  TextColumn get customCoverImagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}
