/// Lottie animation asset paths.
class LottieAssets {
  LottieAssets._();

  /// Boş kart listesi ekranında gösterilen animasyon.
  static const String emptyCards = 'assets/animations/empty_cards.json';

  /// Barkod tarama başarılı olduğunda gösterilen animasyon.
  static const String scanSuccess = 'assets/animations/scan_success.json';

  /// Veri yüklenirken gösterilen loading animasyonu.
  static const String loading = 'assets/animations/loading.json';

  /// Paywall / premium ekranında gösterilen animasyon.
  static const String premiumCrown = 'assets/animations/premium_crown.json';
}

/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Barcode App';
  static const String appVersion = '1.0.0';

  // Barcode types supported
  static const List<String> supportedBarcodeTypes = [
    'QR',
    'CODE128',
    'CODE39',
    'EAN13',
    'EAN8',
    'UPC_A',
    'UPC_E',
    'PDF417',
    'AZTEC',
    'DATA_MATRIX',
  ];

  // IAP SKUs — must match App Store Connect / Google Play Console exactly
  static const String skuProLifetime = 'pro_lifetime';
  static const String skuPackLuxury = 'pack_luxury';
  static const String skuPackNeon = 'pack_neon';

  static const Set<String> allSkus = {
    skuProLifetime,
    skuPackLuxury,
    skuPackNeon,
  };

  // Firebase Function base URLs
  static const String _fnBase =
      'https://us-central1-barcode-app-5919e.cloudfunctions.net';

  static const String iapVerifyUrl = '$_fnBase/iapApi/verify';
  static const String syncPushUrl  = '$_fnBase/syncApi/push';
  static const String syncPullUrl  = '$_fnBase/syncApi/pull';
}
