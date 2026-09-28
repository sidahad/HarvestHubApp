class ProductModel {
  final String id;
  final String title;
  final String category;
  final double price;
  final String unit; // e.g. "kg", "dozen", "liter"
  final String imageUrl;
  final int stock;
  final String farmerId;
  final String farmerName;
  final String farmerPhone;
  final String farmerFarm;
  final double rating;
  final double distanceKm;
  final String marketName;
  final String description;
  final bool isOrganic;
  final int freshnessScore;
  final String priceInsight;
  final int reviewsCount;
  final DateTime? harvestDate;
  bool isFavorite;

  ProductModel({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.unit,
    required this.imageUrl,
    required this.stock,
    required this.farmerId,
    required this.farmerName,
    this.farmerPhone = '',
    required this.farmerFarm,
    required this.rating,
    required this.distanceKm,
    required this.marketName,
    required this.description,
    this.isOrganic = true,
    this.freshnessScore = 95,
    this.priceInsight = 'Direct farm price within standard market range.',
    this.reviewsCount = 18,
    this.harvestDate,
    this.isFavorite = false,
  });

  // Backward compatible alias getters
  String get name => title;
  int get stockKg => stock;
  String get farmLocation => marketName;
}
