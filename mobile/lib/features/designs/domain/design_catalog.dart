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
      name: 'Arctic Frost',
      // Crisp ice-white → vivid sapphire — clean and premium
      gradientColors: ['#F0F8FF', '#BBDEFB', '#64B5F6', '#1565C0'],
    ),
    CoverDesign(
      id: 'free_midnight',
      name: 'Deep Space',
      // True dark navy/space purple — great for AMOLED screens
      gradientColors: ['#0A0A12', '#1A1040', '#2D1B69', '#1A0040'],
    ),
    CoverDesign(
      id: 'free_ocean',
      name: 'Horizon',
      // Vivid sky blue → electric cyan — fresh and modern
      gradientColors: ['#1565C0', '#1E88E5', '#29B6F6', '#00E5FF'],
    ),

    // ── Pack: Luxury ─────────────────────────────────────────────────────────

    CoverDesign(
      id: 'luxury_gold',
      name: '24K Gold',
      isPremium: true,
      packId: IapSkus.packLuxury,
      // Rich amber → liquid gold → back to dark amber (metallic shimmer)
      gradientColors: ['#6B3E00', '#B8870B', '#F5C518', '#E8AE00', '#7B4A00'],
    ),
    CoverDesign(
      id: 'luxury_rose',
      name: 'Rose Gold',
      isPremium: true,
      packId: IapSkus.packLuxury,
      // Deep wine → rose → blush → champagne (luxury feminine gradient)
      gradientColors: ['#6D1F35', '#B5566C', '#E8A0B0', '#F5C8D2', '#D4899A'],
    ),
    CoverDesign(
      id: 'luxury_diamond',
      name: 'Platinum',
      isPremium: true,
      packId: IapSkus.packLuxury,
      // Dark steel → warm silver → near-white → silver (metallic platinum)
      gradientColors: ['#4A5568', '#718096', '#A0AEC0', '#EDF2F7', '#B0BEC5'],
    ),

    // ── Pack: Neon ────────────────────────────────────────────────────────────

    CoverDesign(
      id: 'neon_purple',
      name: 'Ultraviolet',
      isPremium: true,
      packId: IapSkus.packNeon,
      // Deep void → electric violet → hot magenta (UV rave gradient)
      gradientColors: ['#1A004D', '#4400A8', '#7B00E8', '#CC44FF', '#FF00C8'],
    ),
    CoverDesign(
      id: 'neon_electric',
      name: 'Reactor',
      isPremium: true,
      packId: IapSkus.packNeon,
      // Near-black navy → cobalt → electric cyan (plasma energy)
      gradientColors: ['#000A1A', '#003A70', '#0070B8', '#00B4F0'],
    ),
    CoverDesign(
      id: 'neon_cyber',
      name: 'Matrix',
      isPremium: true,
      packId: IapSkus.packNeon,
      // Pure black → deep forest → acid green (cyberpunk terminal)
      gradientColors: ['#030303', '#001A00', '#004400', '#00AA00', '#39FF14'],
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
