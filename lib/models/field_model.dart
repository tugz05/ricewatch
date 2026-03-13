/// Field/crop area model.
class FieldModel {
  const FieldModel({
    required this.id,
    required this.name,
    this.totalAreaHectares,
    this.plantAgeDays,
    this.yieldTons,
    this.waterDepthPercent,
    this.plantHealthPercent,
    this.soilQualityPercent,
    this.pestRiskPercent,
    this.category,
    this.imageUrl,
  });

  final String id;
  final String name;
  final double? totalAreaHectares;
  final int? plantAgeDays;
  final double? yieldTons;
  final int? waterDepthPercent;
  final int? plantHealthPercent;
  final int? soilQualityPercent;
  final int? pestRiskPercent;
  final String? category;
  final String? imageUrl;
}

/// Field content item for "My Fields" list (cards).
class FieldContentItem {
  const FieldContentItem({
    required this.id,
    required this.title,
    required this.description,
    this.fieldId,
    this.imageUrl,
    this.isBookmarked = false,
  });

  final String id;
  final String title;
  final String description;
  final String? fieldId;
  final String? imageUrl;
  final bool isBookmarked;
}
