/// Domain model for a loyalty card.
class LoyaltyCard {
  final int? id;
  final String? remoteId;
  final String merchantName;
  final String barcodeType;
  final String barcodeValue; // Decrypted value (in-memory only)
  final String? coverDesignId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const LoyaltyCard({
    this.id,
    this.remoteId,
    required this.merchantName,
    required this.barcodeType,
    required this.barcodeValue,
    this.coverDesignId,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  LoyaltyCard copyWith({
    int? id,
    String? remoteId,
    String? merchantName,
    String? barcodeType,
    String? barcodeValue,
    String? coverDesignId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return LoyaltyCard(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      merchantName: merchantName ?? this.merchantName,
      barcodeType: barcodeType ?? this.barcodeType,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      coverDesignId: coverDesignId ?? this.coverDesignId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
