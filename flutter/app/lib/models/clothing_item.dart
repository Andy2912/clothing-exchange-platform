class ClothingItem {
  final int clothId;
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final String brand;
  final String size;
  final String conditionRating;
  final double? estimatedValue;

  ClothingItem({
    required this.clothId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.brand,
    required this.size,
    required this.conditionRating,
    required this.estimatedValue,
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      clothId: json['cloth_id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      category: json['category'] ?? '',
      brand: json['brand'] ?? '',
      size: json['size'] ?? '',
      conditionRating: json['condition_rating'] ?? '',
      estimatedValue: json['estimated_value'] != null
          ? (json['estimated_value'] as num).toDouble()
          : null,
    );
  }
}