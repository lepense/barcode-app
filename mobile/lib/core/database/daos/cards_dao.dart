import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/cards_table.dart';

part 'cards_dao.g.dart';

@DriftAccessor(tables: [Cards])
class CardsDao extends DatabaseAccessor<AppDatabase> with _$CardsDaoMixin {
  CardsDao(super.db);

  Future<List<Card>> getAllCards() => select(cards).get();

  Stream<List<Card>> watchAllCards() => select(cards).watch();

  Future<Card> getCardById(int id) =>
      (select(cards)..where((c) => c.id.equals(id))).getSingle();

  Future<int> insertCard(CardsCompanion entry) => into(cards).insert(entry);

  Future<bool> updateCard(Card entry) => update(cards).replace(entry);

  Future<int> deleteCard(int id) =>
      (delete(cards)..where((c) => c.id.equals(id))).go();

  Future<List<Card>> getUnsyncedCards() =>
      (select(cards)..where((c) => c.isSynced.equals(false))).get();

  Future<void> markSynced(int id) =>
      (update(cards)..where((c) => c.id.equals(id)))
          .write(const CardsCompanion(isSynced: Value(true)));
}
