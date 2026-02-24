/// Domain model for a card cover design/template.
class CoverDesign {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final bool isPremium;
  final String? packId;

  const CoverDesign({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.isPremium = false,
    this.packId,
  });
}
