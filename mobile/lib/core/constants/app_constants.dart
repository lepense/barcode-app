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
}
