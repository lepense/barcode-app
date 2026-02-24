import 'card_model.dart';

/// Abstract card repository — implementation will use Drift + optional cloud sync.
abstract class CardRepository {
  Future<List<LoyaltyCard>> getAllCards();
  Stream<List<LoyaltyCard>> watchAllCards();
  Future<LoyaltyCard> getCardById(int id);
  Future<int> addCard(LoyaltyCard card);
  Future<void> updateCard(LoyaltyCard card);
  Future<void> deleteCard(int id);
  Future<List<LoyaltyCard>> getUnsyncedCards();
  Future<void> markSynced(int id);
}
