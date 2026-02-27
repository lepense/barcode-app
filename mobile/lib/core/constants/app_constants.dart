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

  // Firebase Function base URL — replace <PROJECT_ID> with your actual project
  static const String iapVerifyUrl =
      'https://us-central1-<PROJECT_ID>.cloudfunctions.net/iapApi/verify';
}
