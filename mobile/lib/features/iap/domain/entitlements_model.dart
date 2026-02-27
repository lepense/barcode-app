import '../../designs/domain/design_model.dart';
import 'iap_skus.dart';

/// Typed view of the user's current entitlements.
///
/// Constructed from the Drift [Entitlement] DB row.
class EntitlementsModel {
  final bool proLifetime;
  final List<String> purchasedPacks;

  const EntitlementsModel({
    this.proLifetime = false,
    this.purchasedPacks = const [],
  });

  static const EntitlementsModel empty = EntitlementsModel();

  /// Returns true if the user is allowed to use [design].
  bool hasDesign(CoverDesign design) {
    if (!design.isPremium) return true;
    if (proLifetime) return true;
    if (design.packId != null && purchasedPacks.contains(design.packId)) {
      return true;
    }
    return false;
  }

  /// Returns true if [sku] is already owned.
  bool owns(String sku) {
    if (sku == IapSkus.proLifetime) return proLifetime;
    return purchasedPacks.contains(sku);
  }

  EntitlementsModel copyWithProLifetime() => EntitlementsModel(
        proLifetime: true,
        purchasedPacks: purchasedPacks,
      );

  EntitlementsModel copyWithPack(String packId) => EntitlementsModel(
        proLifetime: proLifetime,
        purchasedPacks: [...purchasedPacks, if (!purchasedPacks.contains(packId)) packId],
      );
}
