/// Domain model for a card cover design/template.
///
/// [gradientColors] — 1–4 hex color strings (#RRGGBB) used to render the
/// design preview and the card cover. A single value produces a solid fill.
class CoverDesign {
  final String id;
  final String name;
  final bool isPremium;
  final String? packId;
  final List<String> gradientColors;

  const CoverDesign({
    required this.id,
    required this.name,
    this.isPremium = false,
    this.packId,
    required this.gradientColors,
  });
}
