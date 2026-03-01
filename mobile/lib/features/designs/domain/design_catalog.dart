import '../../iap/domain/iap_skus.dart';
import 'design_model.dart';

/// Static catalog of all card cover designs.
///
/// Free designs are always available.
/// Premium designs require the matching pack SKU or [IapSkus.proLifetime].
abstract class DesignCatalog {
  DesignCatalog._();

  static const List<CoverDesign> all = [
    // ── Free — Gradients ─────────────────────────────────────────────────────

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

    // ── Free — Doodles ───────────────────────────────────────────────────────

    CoverDesign(
      id: 'doodle_polka',
      name: 'Polka Dots',
      gradientColors: ['#E91E63', '#F06292'],
      patternType: DoodlePattern.polkaDots,
    ),
    CoverDesign(
      id: 'doodle_stripes',
      name: 'Stripes',
      gradientColors: ['#1976D2', '#42A5F5'],
      patternType: DoodlePattern.stripes,
    ),
    CoverDesign(
      id: 'doodle_zigzag',
      name: 'Zigzag',
      gradientColors: ['#00897B', '#4DB6AC'],
      patternType: DoodlePattern.zigzag,
    ),
    CoverDesign(
      id: 'doodle_stars',
      name: 'Stars',
      gradientColors: ['#1A004D', '#4400A8', '#7B00E8'],
      patternType: DoodlePattern.stars,
    ),
    CoverDesign(
      id: 'doodle_hearts',
      name: 'Hearts',
      gradientColors: ['#880E4F', '#C2185B', '#F48FB1'],
      patternType: DoodlePattern.hearts,
    ),
    CoverDesign(
      id: 'doodle_crosshatch',
      name: 'Crosshatch',
      gradientColors: ['#37474F', '#546E7A', '#90A4AE'],
      patternType: DoodlePattern.crosshatch,
    ),
    CoverDesign(
      id: 'doodle_waves',
      name: 'Waves',
      gradientColors: ['#006064', '#00838F', '#26C6DA'],
      patternType: DoodlePattern.waves,
    ),
    CoverDesign(
      id: 'doodle_triangles',
      name: 'Triangles',
      gradientColors: ['#E65100', '#F57C00', '#FFB74D'],
      patternType: DoodlePattern.triangles,
    ),
    CoverDesign(
      id: 'doodle_flowers',
      name: 'Flowers',
      gradientColors: ['#6A1B9A', '#AB47BC', '#CE93D8'],
      patternType: DoodlePattern.flowers,
    ),
    CoverDesign(
      id: 'doodle_scribbles',
      name: 'Scribbles',
      gradientColors: ['#1B5E20', '#388E3C', '#81C784'],
      patternType: DoodlePattern.scribbles,
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

  // ── Smart design suggestion ───────────────────────────────────────────────

  /// Returns a free design ID that best matches the [merchantName].
  ///
  /// Uses keyword-category rules first (grocery → green, coffee → teal, etc.).
  /// Falls back to a consistent hash so the same merchant always gets the
  /// same design even without an explicit rule.
  static String suggestDesignFor(String merchantName) {
    if (merchantName.isEmpty) return 'doodle_scribbles';
    final lower = merchantName.toLowerCase();

    // [keywords, designId] — first rule whose ANY keyword appears wins.
    final rules = <List<Object>>[
      // Grocery / supermarket → fresh green
      [
        ['migros', 'bim', 'a101', 'şok', 'sok', 'carrefour', 'walmart',
         'target', 'market', 'grocery', 'supermarket', 'lidl', 'aldi',
         'tesco', 'spar', 'metro', 'rewe', 'edeka', 'kroger', 'whole foods',
         'hypermarket', 'hiper'],
        'doodle_scribbles',
      ],
      // Coffee / café → teal waves
      [
        ['starbucks', 'costa', 'coffee', 'café', 'cafe', 'kahve', 'tchibo',
         'nero', 'pret', 'tim horton'],
        'doodle_waves',
      ],
      // Fast food / restaurant → warm orange
      [
        ['mcdonald', 'burger', 'kfc', 'pizza', 'domino', 'subway', 'taco',
         'wendy', 'popeyes', 'yemek', 'restaurant', 'restoran', 'kebap',
         'doner', 'döner', 'sushi', 'noodle', 'bistro'],
        'doodle_triangles',
      ],
      // Beauty / pharmacy → purple flowers
      [
        ['watsons', 'rossmann', 'sephora', 'eczane', 'pharmacy', 'güzellik',
         'beauty', 'kozmetik', 'parfüm', 'skincare', 'boots', 'ulta',
         'drmax', 'rite aid', 'cvs'],
        'doodle_flowers',
      ],
      // Fashion / clothing → blue stripes
      [
        ['zara', 'h&m', 'hm', 'mango', 'gap', 'lcw', 'lc waikiki',
         'defacto', 'koton', 'bershka', 'mavi', 'giyim', 'fashion',
         'clothing', 'pull&bear', 'massimo dutti', 'uniqlo', 'forever21'],
        'doodle_stripes',
      ],
      // Sports → blue stripes
      [
        ['nike', 'adidas', 'puma', 'reebok', 'new balance', 'decathlon',
         'intersport', 'sport', 'spor', 'athletic', 'fitness', 'gym',
         'yoga', 'columbia', 'patagonia', 'north face'],
        'doodle_stripes',
      ],
      // Electronics / tech → sky blue
      [
        ['mediamarkt', 'media markt', 'teknosa', 'vatan', 'apple store',
         'samsung', 'teknoloji', 'electronic', 'elektronik', 'best buy',
         'currys', 'fnac'],
        'free_ocean',
      ],
      // Travel / airline → sky blue
      [
        ['airline', 'airways', 'pegasus', 'thy', 'lufthansa', 'ryanair',
         'easyjet', 'hotel', 'otel', 'hilton', 'marriott', 'booking',
         'airbnb', 'travel', 'seyahat'],
        'free_ocean',
      ],
      // Gas / fuel → orange triangles
      [
        ['petrol', 'shell', 'opet', 'total', 'fuel', 'benzin', 'bp petrol',
         'lukoil', 'akaryakıt', 'station', 'bp'],
        'doodle_triangles',
      ],
      // Cinema / entertainment → dark stars
      [
        ['cinema', 'sinema', 'cinemaximum', 'netflix', 'disney', 'film',
         'cgv', 'vue', 'odeon', 'kinopolis'],
        'doodle_stars',
      ],
      // Jewelry / luxury → gold stars
      [
        ['altın', 'jewelry', 'mücevher', 'diamond', 'elmas', 'altınbaş',
         'altınyıldız', 'swarovski', 'pandora', 'tiffany'],
        'doodle_stars',
      ],
      // Books / stationery → zigzag
      [
        ['kitap', 'book', 'kırtasiye', 'stationery', 'library', 'kütüphane',
         'barnes', 'waterstones', 'd&r', 'idefix', 'yazıcı'],
        'doodle_zigzag',
      ],
      // Healthcare → hearts
      [
        ['hospital', 'hastane', 'doktor', 'doctor', 'clinic', 'klinik',
         'saglik', 'sağlık', 'health', 'medical'],
        'doodle_hearts',
      ],
    ];

    for (final rule in rules) {
      final words = rule[0] as List<String>;
      final designId = rule[1] as String;
      if (words.any((w) => lower.contains(w))) return designId;
    }

    // Fallback: deterministic hash → free design (same merchant → same design)
    const freeIds = [
      'doodle_scribbles', 'doodle_stripes', 'doodle_zigzag', 'doodle_polka',
      'doodle_waves', 'doodle_triangles', 'doodle_flowers', 'doodle_stars',
      'doodle_hearts', 'doodle_crosshatch', 'free_ocean', 'free_midnight',
      'free_white',
    ];
    final hash = lower.runes.fold<int>(0, (sum, c) => sum + c);
    return freeIds[hash % freeIds.length];
  }
}
