class FarmerModel {
  final String id;
  final String name;
  final String farmName;
  final String location;
  final double? latitude;
  final double? longitude;
  final String marketName;
  final String marketHours;
  final String? city;
  final String? area;
  final double distanceKm;
  final double rating;
  final int reviewCount;
  final String avatarUrl;
  final String bio;
  final bool isVerified;
  final int followerCount;
  final int totalProducts;
  final DateTime? joinedDate;
  bool isFollowing;

  FarmerModel({
    required this.id,
    required this.name,
    required this.farmName,
    required this.location,
    this.latitude,
    this.longitude,
    this.marketName = '',
    this.marketHours = '',
    this.city,
    this.area,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.avatarUrl,
    required this.bio,
    this.isVerified = true,
    required this.followerCount,
    this.totalProducts = 6,
    this.joinedDate,
    this.isFollowing = false,
  });

  String get imageUrl => avatarUrl;
  String get description => bio;
  String get operatingHours => marketHours;
  int get reviewsCount => reviewCount;

  FarmerModel copyWith({
    String? id,
    String? name,
    String? farmName,
    String? location,
    double? latitude,
    double? longitude,
    String? marketName,
    String? marketHours,
    String? city,
    String? area,
    double? distanceKm,
    double? rating,
    int? reviewCount,
    String? avatarUrl,
    String? bio,
    bool? isVerified,
    int? followerCount,
    int? totalProducts,
    DateTime? joinedDate,
    bool? isFollowing,
  }) {
    return FarmerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      farmName: farmName ?? this.farmName,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      marketName: marketName ?? this.marketName,
      marketHours: marketHours ?? this.marketHours,
      city: city ?? this.city,
      area: area ?? this.area,
      distanceKm: distanceKm ?? this.distanceKm,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      followerCount: followerCount ?? this.followerCount,
      totalProducts: totalProducts ?? this.totalProducts,
      joinedDate: joinedDate ?? this.joinedDate,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
