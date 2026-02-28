/// Domain model for a loyalty card.
class LoyaltyCard {
  final int? id;
  final String? remoteId;
  final String merchantName;
  final String barcodeType;
  final String barcodeValue; // Decrypted value (in-memory only)
  final String? coverDesignId;

  /// Absolute path to a user-supplied cover image stored in the app docs dir.
  /// When set, this takes priority over [coverDesignId] in the card cover UI.
  final String? customCoverImagePath;

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
    this.customCoverImagePath,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  // ── copyWith ──────────────────────────────────────────────────────────────
  //
  // Nullable fields use the Object? sentinel pattern so callers can explicitly
  // clear them to null by passing null — the default _sentinel value means
  // "keep the existing value unchanged".

  static const _sentinel = Object();

  LoyaltyCard copyWith({
    Object? remoteId = _sentinel,
    String? merchantName,
    String? barcodeType,
    String? barcodeValue,
    Object? coverDesignId = _sentinel,
    Object? customCoverImagePath = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return LoyaltyCard(
      id: id,
      remoteId: identical(remoteId, _sentinel)
          ? this.remoteId
          : remoteId as String?,
      merchantName: merchantName ?? this.merchantName,
      barcodeType: barcodeType ?? this.barcodeType,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      coverDesignId: identical(coverDesignId, _sentinel)
          ? this.coverDesignId
          : coverDesignId as String?,
      customCoverImagePath: identical(customCoverImagePath, _sentinel)
          ? this.customCoverImagePath
          : customCoverImagePath as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
