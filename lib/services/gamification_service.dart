import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  ENUMS & CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════

/// Customer loyalty tiers
enum CustomerBadge { newBuyer, regularBuyer, loyalCustomer, vipCustomer }

/// Farmer achievement tiers
enum FarmerBadge {
  newFarmer,
  activeFarmer,
  trustedFarmer,
  qualityFarmer,
  topFarmer,
  farmerOfTheMonth,
}

class GamificationConfig {
  // ── Customer point rules ─────────────────────────────────────────────────
  /// Points per Rs.100 spent on a completed order
  static const int pointsPerHundredRupees = 10;

  /// Flat bonus on first completed order
  static const int firstOrderBonus = 50;

  /// Points value of 1 Rs discount (redeem rate)
  static const int pointsPerRupee = 5; // 5 pts = Rs.1 discount

  /// Minimum points needed to redeem
  static const int minRedeemPoints = 100;

  /// Maximum % discount allowed via points redemption
  static const double maxRedeemPercent = 0.20; // 20%

  // ── Customer tier thresholds (total lifetime points) ────────────────────
  static const int regularBuyerThreshold = 200;
  static const int loyalCustomerThreshold = 1000;
  static const int vipCustomerThreshold = 3000;

  // ── Farmer point rules ───────────────────────────────────────────────────
  static const int farmerPointsPerOrder = 20;
  static const int farmerPointsPerFiveStar = 30;
  static const int farmerPointsOnTimeDelivery = 15;
  static const int farmerPointsVerifiedQuality = 25;
  static const int farmerDeductCancellation = -20;
  static const int farmerDeductComplaint = -15;

  // ── Farmer tier thresholds (total lifetime points) ───────────────────────
  static const int activeFarmerThreshold = 100;
  static const int trustedFarmerThreshold = 400;
  static const int qualityFarmerThreshold = 900;
  static const int topFarmerThreshold = 2000;
}

// ═══════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class CustomerGamificationProfile {
  final String userId;
  final int totalPoints;       // lifetime total
  final int currentPoints;     // redeemable balance
  final int completedOrders;
  final double totalSpent;
  final CustomerBadge badge;
  final bool isMonthlyTop;     // "Buyer of the Month"
  final int monthlyPoints;     // points earned this calendar month
  final DateTime lastUpdated;

  const CustomerGamificationProfile({
    required this.userId,
    required this.totalPoints,
    required this.currentPoints,
    required this.completedOrders,
    required this.totalSpent,
    required this.badge,
    required this.isMonthlyTop,
    required this.monthlyPoints,
    required this.lastUpdated,
  });

  /// Points needed to reach the next tier
  int get pointsToNextTier {
    switch (badge) {
      case CustomerBadge.newBuyer:
        return GamificationConfig.regularBuyerThreshold - totalPoints;
      case CustomerBadge.regularBuyer:
        return GamificationConfig.loyalCustomerThreshold - totalPoints;
      case CustomerBadge.loyalCustomer:
        return GamificationConfig.vipCustomerThreshold - totalPoints;
      case CustomerBadge.vipCustomer:
        return 0;
    }
  }

  double get tierProgress {
    switch (badge) {
      case CustomerBadge.newBuyer:
        return (totalPoints / GamificationConfig.regularBuyerThreshold).clamp(0.0, 1.0);
      case CustomerBadge.regularBuyer:
        final range = GamificationConfig.loyalCustomerThreshold - GamificationConfig.regularBuyerThreshold;
        final earned = totalPoints - GamificationConfig.regularBuyerThreshold;
        return (earned / range).clamp(0.0, 1.0);
      case CustomerBadge.loyalCustomer:
        final range = GamificationConfig.vipCustomerThreshold - GamificationConfig.loyalCustomerThreshold;
        final earned = totalPoints - GamificationConfig.loyalCustomerThreshold;
        return (earned / range).clamp(0.0, 1.0);
      case CustomerBadge.vipCustomer:
        return 1.0;
    }
  }

  factory CustomerGamificationProfile.empty(String userId) =>
      CustomerGamificationProfile(
        userId: userId,
        totalPoints: 0,
        currentPoints: 0,
        completedOrders: 0,
        totalSpent: 0,
        badge: CustomerBadge.newBuyer,
        isMonthlyTop: false,
        monthlyPoints: 0,
        lastUpdated: DateTime.now(),
      );

  factory CustomerGamificationProfile.fromMap(
      String userId, Map<String, dynamic> map) {
    final total = (map['totalPoints'] as num?)?.toInt() ?? 0;
    return CustomerGamificationProfile(
      userId: userId,
      totalPoints: total,
      currentPoints: (map['currentPoints'] as num?)?.toInt() ?? 0,
      completedOrders: (map['completedOrders'] as num?)?.toInt() ?? 0,
      totalSpent: (map['totalSpent'] as num?)?.toDouble() ?? 0.0,
      badge: _customerBadgeFromString(map['badge'] as String? ?? ''),
      isMonthlyTop: map['isMonthlyTop'] as bool? ?? false,
      monthlyPoints: (map['monthlyPoints'] as num?)?.toInt() ?? 0,
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'totalPoints': totalPoints,
        'currentPoints': currentPoints,
        'completedOrders': completedOrders,
        'totalSpent': totalSpent,
        'badge': _customerBadgeToString(badge),
        'isMonthlyTop': isMonthlyTop,
        'monthlyPoints': monthlyPoints,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

  static CustomerBadge _customerBadgeFromString(String s) {
    switch (s) {
      case 'regularBuyer':
        return CustomerBadge.regularBuyer;
      case 'loyalCustomer':
        return CustomerBadge.loyalCustomer;
      case 'vipCustomer':
        return CustomerBadge.vipCustomer;
      default:
        return CustomerBadge.newBuyer;
    }
  }

  static String _customerBadgeToString(CustomerBadge b) {
    switch (b) {
      case CustomerBadge.newBuyer:
        return 'newBuyer';
      case CustomerBadge.regularBuyer:
        return 'regularBuyer';
      case CustomerBadge.loyalCustomer:
        return 'loyalCustomer';
      case CustomerBadge.vipCustomer:
        return 'vipCustomer';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────

class FarmerGamificationProfile {
  final String farmerId;
  final int totalPoints;
  final int completedOrders;
  final int fiveStarRatings;
  final int onTimeDeliveries;
  final int verifiedProducts;
  final int cancellations;
  final int complaints;
  final FarmerBadge badge;
  final bool isMonthlyTop;
  final int monthlyPoints;
  final double avgRating;
  final DateTime lastUpdated;

  const FarmerGamificationProfile({
    required this.farmerId,
    required this.totalPoints,
    required this.completedOrders,
    required this.fiveStarRatings,
    required this.onTimeDeliveries,
    required this.verifiedProducts,
    required this.cancellations,
    required this.complaints,
    required this.badge,
    required this.isMonthlyTop,
    required this.monthlyPoints,
    required this.avgRating,
    required this.lastUpdated,
  });

  double get tierProgress {
    switch (badge) {
      case FarmerBadge.newFarmer:
        return (totalPoints / GamificationConfig.activeFarmerThreshold).clamp(0.0, 1.0);
      case FarmerBadge.activeFarmer:
        final range = GamificationConfig.trustedFarmerThreshold - GamificationConfig.activeFarmerThreshold;
        return ((totalPoints - GamificationConfig.activeFarmerThreshold) / range).clamp(0.0, 1.0);
      case FarmerBadge.trustedFarmer:
        final range = GamificationConfig.qualityFarmerThreshold - GamificationConfig.trustedFarmerThreshold;
        return ((totalPoints - GamificationConfig.trustedFarmerThreshold) / range).clamp(0.0, 1.0);
      case FarmerBadge.qualityFarmer:
        final range = GamificationConfig.topFarmerThreshold - GamificationConfig.qualityFarmerThreshold;
        return ((totalPoints - GamificationConfig.qualityFarmerThreshold) / range).clamp(0.0, 1.0);
      case FarmerBadge.topFarmer:
      case FarmerBadge.farmerOfTheMonth:
        return 1.0;
    }
  }

  int get pointsToNextTier {
    switch (badge) {
      case FarmerBadge.newFarmer:
        return GamificationConfig.activeFarmerThreshold - totalPoints;
      case FarmerBadge.activeFarmer:
        return GamificationConfig.trustedFarmerThreshold - totalPoints;
      case FarmerBadge.trustedFarmer:
        return GamificationConfig.qualityFarmerThreshold - totalPoints;
      case FarmerBadge.qualityFarmer:
        return GamificationConfig.topFarmerThreshold - totalPoints;
      case FarmerBadge.topFarmer:
      case FarmerBadge.farmerOfTheMonth:
        return 0;
    }
  }

  factory FarmerGamificationProfile.empty(String farmerId) =>
      FarmerGamificationProfile(
        farmerId: farmerId,
        totalPoints: 0,
        completedOrders: 0,
        fiveStarRatings: 0,
        onTimeDeliveries: 0,
        verifiedProducts: 0,
        cancellations: 0,
        complaints: 0,
        badge: FarmerBadge.newFarmer,
        isMonthlyTop: false,
        monthlyPoints: 0,
        avgRating: 0,
        lastUpdated: DateTime.now(),
      );

  factory FarmerGamificationProfile.fromMap(
      String farmerId, Map<String, dynamic> map) {
    final total = (map['totalPoints'] as num?)?.toInt() ?? 0;
    return FarmerGamificationProfile(
      farmerId: farmerId,
      totalPoints: total,
      completedOrders: (map['completedOrders'] as num?)?.toInt() ?? 0,
      fiveStarRatings: (map['fiveStarRatings'] as num?)?.toInt() ?? 0,
      onTimeDeliveries: (map['onTimeDeliveries'] as num?)?.toInt() ?? 0,
      verifiedProducts: (map['verifiedProducts'] as num?)?.toInt() ?? 0,
      cancellations: (map['cancellations'] as num?)?.toInt() ?? 0,
      complaints: (map['complaints'] as num?)?.toInt() ?? 0,
      badge: _farmerBadgeFromString(map['badge'] as String? ?? ''),
      isMonthlyTop: map['isMonthlyTop'] as bool? ?? false,
      monthlyPoints: (map['monthlyPoints'] as num?)?.toInt() ?? 0,
      avgRating: (map['avgRating'] as num?)?.toDouble() ?? 0.0,
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'totalPoints': totalPoints,
        'completedOrders': completedOrders,
        'fiveStarRatings': fiveStarRatings,
        'onTimeDeliveries': onTimeDeliveries,
        'verifiedProducts': verifiedProducts,
        'cancellations': cancellations,
        'complaints': complaints,
        'badge': _farmerBadgeToString(badge),
        'isMonthlyTop': isMonthlyTop,
        'monthlyPoints': monthlyPoints,
        'avgRating': avgRating,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

  static FarmerBadge _farmerBadgeFromString(String s) {
    switch (s) {
      case 'activeFarmer':
        return FarmerBadge.activeFarmer;
      case 'trustedFarmer':
        return FarmerBadge.trustedFarmer;
      case 'qualityFarmer':
        return FarmerBadge.qualityFarmer;
      case 'topFarmer':
        return FarmerBadge.topFarmer;
      case 'farmerOfTheMonth':
        return FarmerBadge.farmerOfTheMonth;
      default:
        return FarmerBadge.newFarmer;
    }
  }

  static String _farmerBadgeToString(FarmerBadge b) {
    switch (b) {
      case FarmerBadge.newFarmer:
        return 'newFarmer';
      case FarmerBadge.activeFarmer:
        return 'activeFarmer';
      case FarmerBadge.trustedFarmer:
        return 'trustedFarmer';
      case FarmerBadge.qualityFarmer:
        return 'qualityFarmer';
      case FarmerBadge.topFarmer:
        return 'topFarmer';
      case FarmerBadge.farmerOfTheMonth:
        return 'farmerOfTheMonth';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────

class LeaderboardEntry {
  final String userId;
  final String name;
  final String? avatarUrl;
  final int points;
  final int rank;
  final String badgeLabel;
  final String badgeEmoji;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.points,
    required this.rank,
    required this.badgeLabel,
    required this.badgeEmoji,
    this.isCurrentUser = false,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
//  SERVICE
// ═══════════════════════════════════════════════════════════════════════════

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Firestore collection helpers ─────────────────────────────────────────
  DocumentReference _customerRef(String uid) =>
      _db.collection('customer_gamification').doc(uid);

  DocumentReference _farmerRef(String farmerId) =>
      _db.collection('farmer_gamification').doc(farmerId);

  // ─────────────────────────────────────────────────────────────────────────
  //  CUSTOMER  —  read profile
  // ─────────────────────────────────────────────────────────────────────────

  Future<CustomerGamificationProfile> getCustomerProfile(String uid) async {
    try {
      final doc = await _customerRef(uid).get();
      if (!doc.exists) return CustomerGamificationProfile.empty(uid);
      return CustomerGamificationProfile.fromMap(
          uid, doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('GamificationService: getCustomerProfile error: $e');
      return CustomerGamificationProfile.empty(uid);
    }
  }

  Stream<CustomerGamificationProfile> customerProfileStream(String uid) =>
      _customerRef(uid).snapshots().map((doc) {
        if (!doc.exists) return CustomerGamificationProfile.empty(uid);
        return CustomerGamificationProfile.fromMap(
            uid, doc.data() as Map<String, dynamic>);
      });

  // ─────────────────────────────────────────────────────────────────────────
  //  CUSTOMER  —  award points on order completion
  // ─────────────────────────────────────────────────────────────────────────

  /// Call this when an order's status changes to 'Delivered'.
  /// Uses a Firestore transaction so points cannot be double-awarded.
  Future<void> awardCustomerOrderPoints({
    required String customerId,
    required String orderId,
    required double orderTotal,
  }) async {
    final docRef = _customerRef(customerId);
    // Guard doc: track awarded orders to prevent duplicates
    final awardedRef = docRef.collection('awarded_orders').doc(orderId);

    try {
      await _db.runTransaction((txn) async {
        final awardedSnap = await txn.get(awardedRef);
        if (awardedSnap.exists) return; // already awarded — skip

        final profileSnap = await txn.get(docRef);
        final existing = profileSnap.exists
            ? CustomerGamificationProfile.fromMap(
                customerId, profileSnap.data() as Map<String, dynamic>)
            : CustomerGamificationProfile.empty(customerId);

        // Calculate points: Rs.100 = 10 pts
        int earned =
            ((orderTotal / 100) * GamificationConfig.pointsPerHundredRupees)
                .floor();

        // First order bonus
        if (existing.completedOrders == 0) {
          earned += GamificationConfig.firstOrderBonus;
        }

        final newTotal = existing.totalPoints + earned;
        final newCurrent = existing.currentPoints + earned;
        final newCompleted = existing.completedOrders + 1;
        final newSpent = existing.totalSpent + orderTotal;
        final newBadge = _computeCustomerBadge(newTotal);

        // Monthly points: reset if new month
        final now = DateTime.now();
        final lastUpdate = existing.lastUpdated;
        final sameMonth = now.year == lastUpdate.year && now.month == lastUpdate.month;
        final newMonthly = sameMonth ? existing.monthlyPoints + earned : earned;

        final updated = {
          'totalPoints': newTotal,
          'currentPoints': newCurrent,
          'completedOrders': newCompleted,
          'totalSpent': newSpent,
          'badge': CustomerGamificationProfile._customerBadgeToString(newBadge),
          'monthlyPoints': newMonthly,
          'lastUpdated': FieldValue.serverTimestamp(),
          'isMonthlyTop': existing.isMonthlyTop,
        };

        txn.set(docRef, updated, SetOptions(merge: true));
        txn.set(awardedRef, {
          'orderId': orderId,
          'pointsEarned': earned,
          'awardedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('GamificationService: awardCustomerOrderPoints error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  CUSTOMER  —  redeem points for discount
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the discount amount in Rupees for the given pointsToRedeem.
  static double calculateDiscount(int pointsToRedeem) =>
      pointsToRedeem / GamificationConfig.pointsPerRupee;

  /// Deducts points after a successful order where points were redeemed.
  /// Pass [pointsUsed] = 0 if no redemption.
  Future<void> redeemPoints({
    required String customerId,
    required String orderId,
    required int pointsUsed,
  }) async {
    if (pointsUsed <= 0) return;
    final docRef = _customerRef(customerId);
    final redeemedRef = docRef.collection('redeemed_orders').doc(orderId);

    try {
      await _db.runTransaction((txn) async {
        final redeemedSnap = await txn.get(redeemedRef);
        if (redeemedSnap.exists) return;

        final profileSnap = await txn.get(docRef);
        if (!profileSnap.exists) return;
        final profile = CustomerGamificationProfile.fromMap(
            customerId, profileSnap.data() as Map<String, dynamic>);

        final safeDeduct = pointsUsed.clamp(0, profile.currentPoints);
        txn.update(docRef, {
          'currentPoints': FieldValue.increment(-safeDeduct),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        txn.set(redeemedRef, {
          'orderId': orderId,
          'pointsUsed': safeDeduct,
          'redeemedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('GamificationService: redeemPoints error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  FARMER  —  read profile
  // ─────────────────────────────────────────────────────────────────────────

  Future<FarmerGamificationProfile> getFarmerProfile(String farmerId) async {
    try {
      final doc = await _farmerRef(farmerId).get();
      if (!doc.exists) return FarmerGamificationProfile.empty(farmerId);
      return FarmerGamificationProfile.fromMap(
          farmerId, doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('GamificationService: getFarmerProfile error: $e');
      return FarmerGamificationProfile.empty(farmerId);
    }
  }

  Stream<FarmerGamificationProfile> farmerProfileStream(String farmerId) =>
      _farmerRef(farmerId).snapshots().map((doc) {
        if (!doc.exists) return FarmerGamificationProfile.empty(farmerId);
        return FarmerGamificationProfile.fromMap(
            farmerId, doc.data() as Map<String, dynamic>);
      });

  // ─────────────────────────────────────────────────────────────────────────
  //  FARMER  —  award / deduct points
  // ─────────────────────────────────────────────────────────────────────────

  /// Call when an order is marked 'Delivered' for the farmer.
  Future<void> awardFarmerOrderPoints({
    required String farmerId,
    required String orderId,
    required bool isOnTime,
  }) async {
    final docRef = _farmerRef(farmerId);
    final awardedRef = docRef.collection('awarded_orders').doc(orderId);

    try {
      await _db.runTransaction((txn) async {
        final awardedSnap = await txn.get(awardedRef);
        if (awardedSnap.exists) return;

        final profileSnap = await txn.get(docRef);
        final existing = profileSnap.exists
            ? FarmerGamificationProfile.fromMap(
                farmerId, profileSnap.data() as Map<String, dynamic>)
            : FarmerGamificationProfile.empty(farmerId);

        int earned = GamificationConfig.farmerPointsPerOrder;
        if (isOnTime) earned += GamificationConfig.farmerPointsOnTimeDelivery;

        final newTotal = existing.totalPoints + earned;
        final newBadge = _computeFarmerBadge(newTotal);

        final now = DateTime.now();
        final lastUpdate = existing.lastUpdated;
        final sameMonth = now.year == lastUpdate.year && now.month == lastUpdate.month;
        final newMonthly = sameMonth ? existing.monthlyPoints + earned : earned;

        txn.set(
          docRef,
          {
            'totalPoints': newTotal,
            'completedOrders': FieldValue.increment(1),
            'onTimeDeliveries':
                isOnTime ? FieldValue.increment(1) : existing.onTimeDeliveries,
            'badge': FarmerGamificationProfile._farmerBadgeToString(newBadge),
            'monthlyPoints': newMonthly,
            'lastUpdated': FieldValue.serverTimestamp(),
            'isMonthlyTop': existing.isMonthlyTop,
            'cancellations': existing.cancellations,
            'complaints': existing.complaints,
            'fiveStarRatings': existing.fiveStarRatings,
            'verifiedProducts': existing.verifiedProducts,
            'avgRating': existing.avgRating,
          },
          SetOptions(merge: true),
        );
        txn.set(awardedRef, {
          'orderId': orderId,
          'pointsEarned': earned,
          'isOnTime': isOnTime,
          'awardedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('GamificationService: awardFarmerOrderPoints error: $e');
    }
  }

  /// Award farmer points for a 5-star rating received.
  Future<void> awardFarmerRatingPoints({
    required String farmerId,
    required String reviewId,
    required double rating,
  }) async {
    if (rating < 5.0) return;
    final docRef = _farmerRef(farmerId);
    final awardedRef = docRef.collection('awarded_ratings').doc(reviewId);

    try {
      await _db.runTransaction((txn) async {
        final snap = await txn.get(awardedRef);
        if (snap.exists) return;

        txn.update(docRef, {
          'totalPoints':
              FieldValue.increment(GamificationConfig.farmerPointsPerFiveStar),
          'monthlyPoints':
              FieldValue.increment(GamificationConfig.farmerPointsPerFiveStar),
          'fiveStarRatings': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        txn.set(awardedRef, {
          'reviewId': reviewId,
          'pointsEarned': GamificationConfig.farmerPointsPerFiveStar,
          'awardedAt': FieldValue.serverTimestamp(),
        });
      });
      // Re-evaluate badge after rating points added
      await _refreshFarmerBadge(farmerId);
    } catch (e) {
      debugPrint('GamificationService: awardFarmerRatingPoints error: $e');
    }
  }

  /// Award farmer points for verified product quality.
  Future<void> awardFarmerQualityPoints({
    required String farmerId,
    required String productId,
  }) async {
    final docRef = _farmerRef(farmerId);
    final awardedRef = docRef.collection('awarded_quality').doc(productId);

    try {
      await _db.runTransaction((txn) async {
        final snap = await txn.get(awardedRef);
        if (snap.exists) return;

        txn.update(docRef, {
          'totalPoints':
              FieldValue.increment(GamificationConfig.farmerPointsVerifiedQuality),
          'monthlyPoints':
              FieldValue.increment(GamificationConfig.farmerPointsVerifiedQuality),
          'verifiedProducts': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        txn.set(awardedRef, {
          'productId': productId,
          'pointsEarned': GamificationConfig.farmerPointsVerifiedQuality,
          'awardedAt': FieldValue.serverTimestamp(),
        });
      });
      await _refreshFarmerBadge(farmerId);
    } catch (e) {
      debugPrint('GamificationService: awardFarmerQualityPoints error: $e');
    }
  }

  /// Deduct points for a cancellation or customer complaint.
  Future<void> deductFarmerPoints({
    required String farmerId,
    required bool isCancellation,
    String? relatedId,
  }) async {
    final deduction = isCancellation
        ? GamificationConfig.farmerDeductCancellation
        : GamificationConfig.farmerDeductComplaint;

    try {
      await _farmerRef(farmerId).update({
        'totalPoints': FieldValue.increment(deduction),
        'monthlyPoints': FieldValue.increment(deduction),
        if (isCancellation) 'cancellations': FieldValue.increment(1),
        if (!isCancellation) 'complaints': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      await _refreshFarmerBadge(farmerId);
    } catch (e) {
      debugPrint('GamificationService: deductFarmerPoints error: $e');
    }
  }

  Future<void> _refreshFarmerBadge(String farmerId) async {
    try {
      final doc = await _farmerRef(farmerId).get();
      if (!doc.exists) return;
      final total = (doc.data() as Map<String, dynamic>)['totalPoints'] as int? ?? 0;
      final badge = _computeFarmerBadge(total);
      await _farmerRef(farmerId).update({
        'badge': FarmerGamificationProfile._farmerBadgeToString(badge),
      });
    } catch (e) {
      debugPrint('GamificationService: _refreshFarmerBadge error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  LEADERBOARDS
  // ─────────────────────────────────────────────────────────────────────────

  /// Top 20 customers by monthly points.
  Future<List<LeaderboardEntry>> getCustomerLeaderboard(
      {String? currentUserId}) async {
    try {
      final snap = await _db
          .collection('customer_gamification')
          .orderBy('monthlyPoints', descending: true)
          .limit(20)
          .get();

      // Also fetch display names from users collection in parallel
      final entries = <LeaderboardEntry>[];
      int rank = 0;
      for (final doc in snap.docs) {
        rank++;
        final data = doc.data();
        final uid = doc.id;
        String name = 'Customer';
        String? avatar;
        try {
          final userDoc = await _db.collection('users').doc(uid).get();
          if (userDoc.exists) {
            name = userDoc.data()?['fullName'] as String? ?? 'Customer';
            avatar = userDoc.data()?['profilePic'] as String?;
          }
        } catch (_) {}

        final badge = CustomerGamificationProfile._customerBadgeFromString(
            data['badge'] as String? ?? '');
        entries.add(LeaderboardEntry(
          userId: uid,
          name: name,
          avatarUrl: avatar,
          points: (data['monthlyPoints'] as num?)?.toInt() ?? 0,
          rank: rank,
          badgeLabel: customerBadgeLabel(badge),
          badgeEmoji: customerBadgeEmoji(badge),
          isCurrentUser: uid == currentUserId,
        ));
      }
      return entries;
    } catch (e) {
      debugPrint('GamificationService: getCustomerLeaderboard error: $e');
      return [];
    }
  }

  /// Top 20 farmers by monthly points.
  Future<List<LeaderboardEntry>> getFarmerLeaderboard(
      {String? currentFarmerId}) async {
    try {
      final snap = await _db
          .collection('farmer_gamification')
          .orderBy('monthlyPoints', descending: true)
          .limit(20)
          .get();

      final entries = <LeaderboardEntry>[];
      int rank = 0;
      for (final doc in snap.docs) {
        rank++;
        final data = doc.data();
        final fid = doc.id;
        String name = 'Farmer';
        String? avatar;
        try {
          final farmerDoc = await _db.collection('farmers').doc(fid).get();
          if (farmerDoc.exists) {
            name = farmerDoc.data()?['name'] as String? ?? 'Farmer';
            avatar = farmerDoc.data()?['avatarUrl'] as String?;
          }
        } catch (_) {}

        final badge = FarmerGamificationProfile._farmerBadgeFromString(
            data['badge'] as String? ?? '');
        entries.add(LeaderboardEntry(
          userId: fid,
          name: name,
          avatarUrl: avatar,
          points: (data['monthlyPoints'] as num?)?.toInt() ?? 0,
          rank: rank,
          badgeLabel: farmerBadgeLabel(badge),
          badgeEmoji: farmerBadgeEmoji(badge),
          isCurrentUser: fid == currentFarmerId,
        ));
      }
      return entries;
    } catch (e) {
      debugPrint('GamificationService: getFarmerLeaderboard error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BADGE COMPUTATION HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  static CustomerBadge _computeCustomerBadge(int totalPoints) {
    if (totalPoints >= GamificationConfig.vipCustomerThreshold) {
      return CustomerBadge.vipCustomer;
    } else if (totalPoints >= GamificationConfig.loyalCustomerThreshold) {
      return CustomerBadge.loyalCustomer;
    } else if (totalPoints >= GamificationConfig.regularBuyerThreshold) {
      return CustomerBadge.regularBuyer;
    }
    return CustomerBadge.newBuyer;
  }

  static FarmerBadge _computeFarmerBadge(int totalPoints) {
    if (totalPoints >= GamificationConfig.topFarmerThreshold) {
      return FarmerBadge.topFarmer;
    } else if (totalPoints >= GamificationConfig.qualityFarmerThreshold) {
      return FarmerBadge.qualityFarmer;
    } else if (totalPoints >= GamificationConfig.trustedFarmerThreshold) {
      return FarmerBadge.trustedFarmer;
    } else if (totalPoints >= GamificationConfig.activeFarmerThreshold) {
      return FarmerBadge.activeFarmer;
    }
    return FarmerBadge.newFarmer;
  }

  static CustomerBadge customerBadgeFromKey(String s) =>
      CustomerGamificationProfile._customerBadgeFromString(s);

  static FarmerBadge farmerBadgeFromKey(String s) =>
      FarmerGamificationProfile._farmerBadgeFromString(s);

  // ─────────────────────────────────────────────────────────────────────────
  //  DISPLAY HELPERS (static — usable from UI without async)
  // ─────────────────────────────────────────────────────────────────────────

  static String customerBadgeLabel(CustomerBadge b) {
    switch (b) {
      case CustomerBadge.newBuyer:
        return 'New Buyer';
      case CustomerBadge.regularBuyer:
        return 'Regular Buyer';
      case CustomerBadge.loyalCustomer:
        return 'Loyal Customer';
      case CustomerBadge.vipCustomer:
        return 'VIP Customer';
    }
  }

  static IconData customerBadgeIcon(CustomerBadge b) {
    switch (b) {
      case CustomerBadge.newBuyer:
        return Icons.eco;
      case CustomerBadge.regularBuyer:
        return Icons.shopping_cart;
      case CustomerBadge.loyalCustomer:
        return Icons.favorite;
      case CustomerBadge.vipCustomer:
        return Icons.workspace_premium;
    }
  }

  static String customerBadgeEmoji(CustomerBadge b) => '';

  static Color customerBadgeColor(CustomerBadge b) {
    switch (b) {
      case CustomerBadge.newBuyer:
        return const Color(0xFF8FA497);
      case CustomerBadge.regularBuyer:
        return const Color(0xFF88AB75);
      case CustomerBadge.loyalCustomer:
        return const Color(0xFF52B788);
      case CustomerBadge.vipCustomer:
        return const Color(0xFFE9C46A);
    }
  }

  static String farmerBadgeLabel(FarmerBadge b) {
    switch (b) {
      case FarmerBadge.newFarmer:
        return 'New Farmer';
      case FarmerBadge.activeFarmer:
        return 'Active Farmer';
      case FarmerBadge.trustedFarmer:
        return 'Trusted Farmer';
      case FarmerBadge.qualityFarmer:
        return 'Quality Farmer';
      case FarmerBadge.topFarmer:
        return 'Top Farmer';
      case FarmerBadge.farmerOfTheMonth:
        return 'Farmer of the Month';
    }
  }

  static IconData farmerBadgeIcon(FarmerBadge b) {
    switch (b) {
      case FarmerBadge.newFarmer:
        return Icons.agriculture;
      case FarmerBadge.activeFarmer:
        return Icons.bolt;
      case FarmerBadge.trustedFarmer:
        return Icons.verified;
      case FarmerBadge.qualityFarmer:
        return Icons.star;
      case FarmerBadge.topFarmer:
        return Icons.emoji_events;
      case FarmerBadge.farmerOfTheMonth:
        return Icons.workspace_premium;
    }
  }

  static String farmerBadgeEmoji(FarmerBadge b) => '';

  static Color farmerBadgeColor(FarmerBadge b) {
    switch (b) {
      case FarmerBadge.newFarmer:
        return const Color(0xFF8FA497);
      case FarmerBadge.activeFarmer:
        return const Color(0xFF88AB75);
      case FarmerBadge.trustedFarmer:
        return const Color(0xFF52B788);
      case FarmerBadge.qualityFarmer:
        return const Color(0xFF48CAE4);
      case FarmerBadge.topFarmer:
        return const Color(0xFFE9C46A);
      case FarmerBadge.farmerOfTheMonth:
        return const Color(0xFFFFD700);
    }
  }

  /// Returns how many Rs discount the user can get for [points] points.
  static String formatPointsAsDiscount(int points) {
    final rs = points / GamificationConfig.pointsPerRupee;
    return 'Rs ${rs.toStringAsFixed(0)}';
  }
}
