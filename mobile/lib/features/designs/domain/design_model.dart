/// Doodle / illustrated pattern overlay that can be drawn on a card cover.
enum DoodlePattern {
  polkaDots,
  stripes,
  zigzag,
  stars,
  hearts,
  crosshatch,
  waves,
  triangles,
  flowers,
  scribbles,
}

/// Domain model for a card cover design/template.
///
/// [gradientColors] — 1–4 hex color strings (#RRGGBB) used to render the
/// design preview and the card cover. A single value produces a solid fill.
///
/// [patternType] — optional doodle overlay drawn on top of the gradient.
class CoverDesign {
  final String id;
  final String name;
  final bool isPremium;
  final String? packId;
  final List<String> gradientColors;
  final DoodlePattern? patternType;

  const CoverDesign({
    required this.id,
    required this.name,
    this.isPremium = false,
    this.packId,
    required this.gradientColors,
    this.patternType,
  });
}
