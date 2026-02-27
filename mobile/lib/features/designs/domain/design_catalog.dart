import '../../iap/domain/iap_skus.dart';
import 'design_model.dart';

/// Static catalog of all card cover designs.
///
/// Free designs are always available.
/// Premium designs require the matching pack SKU or [IapSkus.proLifetime].
abstract class DesignCatalog {
  DesignCatalog._();

  static const List<CoverDesign> all = [
    // ── Free ─────────────────────────────────────────────────────────────────
    CoverDesign(
      id: 'free_white',
      name: 'Clean White',
      gradientColors: ['#F8F9FA', '#E9ECEF'],
    ),
    CoverDesign(
      id: 'free_midnight',
      name: 'Midnight',
      gradientColors: ['#1A1A2E', '#16213E'],
    ),
    CoverDesign(
      id: 'free_ocean',
      name: 'Ocean Blue',
      gradientColors: ['#2193B0', '#6DD5FA'],
    ),

    // ── Pack: Luxury ─────────────────────────────────────────────────────────
    CoverDesign(
      id: 'luxury_gold',
      name: 'Gold Rush',
      isPremium: true,
      packId: IapSkus.packLuxury,
      gradientColors: ['#F7971E', '#FFD200'],
    ),
    CoverDesign(
      id: 'luxury_rose',
      name: 'Rose Gold',
      isPremium: true,
      packId: IapSkus.packLuxury,
      gradientColors: ['#B76E79', '#E8B4B8', '#F7CAC9'],
    ),
    CoverDesign(
      id: 'luxury_diamond',
      name: 'Diamond',
      isPremium: true,
      packId: IapSkus.packLuxury,
      gradientColors: ['#C9D6FF', '#E2E2E2'],
    ),

    // ── Pack: Neon ────────────────────────────────────────────────────────────
    CoverDesign(
      id: 'neon_purple',
      name: 'Neon Purple',
      isPremium: true,
      packId: IapSkus.packNeon,
      gradientColors: ['#7B2FF7', '#F107A3'],
    ),
    CoverDesign(
      id: 'neon_electric',
      name: 'Electric Blue',
      isPremium: true,
      packId: IapSkus.packNeon,
      gradientColors: ['#00C6FF', '#0072FF'],
    ),
    CoverDesign(
      id: 'neon_cyber',
      name: 'Cyber Green',
      isPremium: true,
      packId: IapSkus.packNeon,
      gradientColors: ['#39FF14', '#00F5FF'],
    ),
  ];

  static CoverDesign? findById(String id) {
    try {
      return all.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
