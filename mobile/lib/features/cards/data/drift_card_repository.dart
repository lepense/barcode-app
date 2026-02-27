import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/cards_table.dart';
import '../../../core/services/encryption_service.dart';
import '../domain/card_model.dart';
import '../domain/card_repository.dart';

/// Drift-backed implementation of [CardRepository].
class DriftCardRepository implements CardRepository {
  final AppDatabase _db;
  final EncryptionService _encryption;
  final Uuid _uuid;

  DriftCardRepository(this._db, this._encryption) : _uuid = const Uuid();

  // --- Mapping helpers ---

  LoyaltyCard _fromRow(Card row) {
    return LoyaltyCard(
      id: row.id,
      remoteId: row.remoteId,
      merchantName: row.merchantName,
      barcodeType: row.barcodeType,
      barcodeValue: _encryption.decrypt(row.barcodeValueEncrypted),
      coverDesignId: row.coverDesignId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isSynced: row.isSynced,
    );
  }

  CardsCompanion _toCompanion(LoyaltyCard card) {
    final now = DateTime.now();
    return CardsCompanion(
      remoteId: Value(card.remoteId ?? _uuid.v4()),
      merchantName: Value(card.merchantName),
      barcodeType: Value(card.barcodeType),
      barcodeValueEncrypted: Value(_encryption.encrypt(card.barcodeValue)),
      coverDesignId: Value(card.coverDesignId),
      createdAt: Value(card.createdAt),
      updatedAt: Value(now),
      isSynced: const Value(false),
    );
  }

  // --- CardRepository implementation ---

  @override
  Future<List<LoyaltyCard>> getAllCards() async {
    final rows = await _db.cardsDao.getAllCards();
    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<LoyaltyCard>> watchAllCards() {
    return _db.cardsDao.watchAllCards().map(
          (rows) => rows.map(_fromRow).toList(),
        );
  }

  @override
  Future<LoyaltyCard> getCardById(int id) async {
    final row = await _db.cardsDao.getCardById(id);
    return _fromRow(row);
  }

  @override
  Future<int> addCard(LoyaltyCard card) {
    return _db.cardsDao.insertCard(_toCompanion(card));
  }

  @override
  Future<void> updateCard(LoyaltyCard card) async {
    final now = DateTime.now();
    await _db.cardsDao.updateCard(
      Card(
        id: card.id!,
        remoteId: card.remoteId,
        merchantName: card.merchantName,
        barcodeType: card.barcodeType,
        barcodeValueEncrypted: _encryption.encrypt(card.barcodeValue),
        coverDesignId: card.coverDesignId,
        createdAt: card.createdAt,
        updatedAt: now,
        isSynced: false,
      ),
    );
  }

  @override
  Future<void> deleteCard(int id) async {
    await _db.cardsDao.deleteCard(id);
  }

  @override
  Future<List<LoyaltyCard>> getUnsyncedCards() async {
    final rows = await _db.cardsDao.getUnsyncedCards();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> markSynced(int id) {
    return _db.cardsDao.markSynced(id);
  }
}
