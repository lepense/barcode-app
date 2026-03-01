/// IAP SKU identifiers.
///
/// These must match exactly what is configured in App Store Connect
/// and Google Play Console.
abstract class IapSkus {
  IapSkus._();

  static const String proLifetime = 'pro_lifetime';
  static const String packLuxury = 'pack_luxury';
  static const String packNeon = 'pack_neon';

  static const Set<String> all = {proLifetime, packLuxury, packNeon};

  static String packDisplayName(String packId) {
    switch (packId) {
      case packLuxury:
        return 'Luxury Pack';
      case packNeon:
        return 'Neon Pack';
      default:
        return packId;
    }
  }
}
