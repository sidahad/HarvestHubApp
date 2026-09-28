import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

// ── Enums ──────────────────────────────────────────────────────────────────

enum ReportReason {
  spam,
  harassment,
  fakeProfile,
  inappropriateContent,
  fraud,
  other,
}

enum TrustLevel {
  newUser,      // < 5 transactions
  regularUser,  // 5–19 transactions
  trustedUser,  // 20–49 transactions
  premiumUser,  // 50+ transactions
}

// ── Data models ────────────────────────────────────────────────────────────

class UserReport {
  final String id;
  final String reportedUserId;
  final String reportedByUserId;
  final ReportReason reason;
  final String? description;
  final DateTime createdAt;
  final String status; // 'pending' | 'reviewed' | 'dismissed'

  const UserReport({
    required this.id,
    required this.reportedUserId,
    required this.reportedByUserId,
    required this.reason,
    this.description,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'reportedUserId': reportedUserId,
        'reportedByUserId': reportedByUserId,
        'reason': reason.toString().split('.').last,
        'description': description ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': status,
      };

  factory UserReport.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserReport(
      id: doc.id,
      reportedUserId: d['reportedUserId'] as String,
      reportedByUserId: d['reportedByUserId'] as String,
      reason: _reasonFromString(d['reason'] as String? ?? 'other'),
      description: d['description'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: d['status'] as String? ?? 'pending',
    );
  }

  static ReportReason _reasonFromString(String s) {
    switch (s) {
      case 'spam':
        return ReportReason.spam;
      case 'harassment':
        return ReportReason.harassment;
      case 'fakeProfile':
        return ReportReason.fakeProfile;
      case 'inappropriateContent':
        return ReportReason.inappropriateContent;
      case 'fraud':
        return ReportReason.fraud;
      default:
        return ReportReason.other;
    }
  }
}

class SafetyProfile {
  final String userId;
  final TrustLevel trustLevel;
  final int safetyScore;       // 0–100
  final bool isVerified;
  final bool isTrustedSeller;
  final int totalTransactions;
  final int reportsReceived;
  final List<String> badges;

  const SafetyProfile({
    required this.userId,
    required this.trustLevel,
    required this.safetyScore,
    required this.isVerified,
    required this.isTrustedSeller,
    required this.totalTransactions,
    required this.reportsReceived,
    required this.badges,
  });

  factory SafetyProfile.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final txCount = (d['totalTransactions'] as num?)?.toInt() ?? 0;
    final reports = (d['reportsReceived'] as num?)?.toInt() ?? 0;

    return SafetyProfile(
      userId: doc.id,
      trustLevel: _levelFromTransactions(txCount),
      safetyScore: _computeScore(txCount, reports),
      isVerified: d['isVerified'] as bool? ?? false,
      isTrustedSeller: d['isTrustedSeller'] as bool? ?? false,
      totalTransactions: txCount,
      reportsReceived: reports,
      badges: List<String>.from(d['badges'] ?? []),
    );
  }

  static TrustLevel _levelFromTransactions(int count) {
    if (count >= 50) return TrustLevel.premiumUser;
    if (count >= 20) return TrustLevel.trustedUser;
    if (count >= 5) return TrustLevel.regularUser;
    return TrustLevel.newUser;
  }

  static int _computeScore(int txCount, int reports) {
    // Base score from transactions (max 80)
    final base = (txCount * 2).clamp(0, 80);
    // Penalty for reports (−10 each, max −80)
    final penalty = (reports * 10).clamp(0, 80);
    return (base - penalty + 20).clamp(0, 100);
  }
}

// ── Service ────────────────────────────────────────────────────────────────

class TrustSafetyService {
  static final TrustSafetyService _instance = TrustSafetyService._internal();
  factory TrustSafetyService() => _instance;
  TrustSafetyService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  // ── Report a user ────────────────────────────────────────────────────────

  Future<void> reportUser({
    required String targetUserId,
    required ReportReason reason,
    String? description,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');
    if (targetUserId == currentUser.uid) {
      throw Exception('You cannot report yourself');
    }

    // Prevent duplicate reports within 24 hours
    final existing = await _db
        .collection('reports')
        .where('reportedUserId', isEqualTo: targetUserId)
        .where('reportedByUserId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final lastReport =
          (existing.docs.first.data()['createdAt'] as Timestamp?)?.toDate();
      if (lastReport != null &&
          DateTime.now().difference(lastReport).inHours < 24) {
        throw Exception(
            'You have already reported this user recently. Please wait 24 hours.');
      }
    }

    final report = UserReport(
      id: '',
      reportedUserId: targetUserId,
      reportedByUserId: currentUser.uid,
      reason: reason,
      description: description,
      createdAt: DateTime.now(),
      status: 'pending',
    );

    final batch = _db.batch();

    // Add report document
    final reportRef = _db.collection('reports').doc();
    batch.set(reportRef, report.toMap());

    // Increment report counter on the target user's safety profile
    final safetyRef = _db.collection('safety_profiles').doc(targetUserId);
    batch.set(
      safetyRef,
      {'reportsReceived': FieldValue.increment(1)},
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  // ── Block / unblock ──────────────────────────────────────────────────────

  Future<void> blockUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    await _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('blocked_users')
        .doc(targetUserId)
        .set({
      'blockedAt': FieldValue.serverTimestamp(),
      'blockedUserId': targetUserId,
    });
  }

  Future<void> unblockUser(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    await _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('blocked_users')
        .doc(targetUserId)
        .delete();
  }

  Future<bool> isUserBlocked(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final doc = await _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('blocked_users')
        .doc(targetUserId)
        .get();

    return doc.exists;
  }

  /// Stream of all users blocked by the current user
  Stream<List<String>> blockedUserIdsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('blocked_users')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  // ── Safety profile ───────────────────────────────────────────────────────

  Future<SafetyProfile?> getSafetyProfile(String userId) async {
    try {
      final doc =
          await _db.collection('safety_profiles').doc(userId).get();
      if (!doc.exists) {
        // Return a default profile for new users
        return SafetyProfile(
          userId: userId,
          trustLevel: TrustLevel.newUser,
          safetyScore: 20,
          isVerified: false,
          isTrustedSeller: false,
          totalTransactions: 0,
          reportsReceived: 0,
          badges: [],
        );
      }
      return SafetyProfile.fromDoc(doc);
    } catch (e) {
      debugPrint('TrustSafetyService: error fetching profile for $userId: $e');
      return null;
    }
  }

  Stream<SafetyProfile?> safetyProfileStream(String userId) {
    return _db
        .collection('safety_profiles')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return SafetyProfile(
          userId: userId,
          trustLevel: TrustLevel.newUser,
          safetyScore: 20,
          isVerified: false,
          isTrustedSeller: false,
          totalTransactions: 0,
          reportsReceived: 0,
          badges: [],
        );
      }
      return SafetyProfile.fromDoc(doc);
    });
  }

  /// Fetch reports submitted BY the current user
  Future<List<UserReport>> getMyReports() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    final snap = await _db
        .collection('reports')
        .where('reportedByUserId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map(UserReport.fromDoc).toList();
  }

  // ── Helpers for UI ───────────────────────────────────────────────────────

  /// Human-readable label for a ReportReason (used when AppLocalizations
  /// is not available, e.g. in service layer logs).
  static String reasonLabel(ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.fakeProfile:
        return 'Fake Profile';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.fraud:
        return 'Fraud / Scam';
      case ReportReason.other:
        return 'Other';
    }
  }

  static Color trustLevelColor(TrustLevel level) {
    switch (level) {
      case TrustLevel.newUser:
        return const Color(0xFF8EAA95);
      case TrustLevel.regularUser:
        return const Color(0xFF88AB75);
      case TrustLevel.trustedUser:
        return const Color(0xFF4CAF50);
      case TrustLevel.premiumUser:
        return const Color(0xFFFFD700);
    }
  }

  static IconData trustLevelIconData(TrustLevel level) {
    switch (level) {
      case TrustLevel.newUser:
        return Icons.eco;
      case TrustLevel.regularUser:
        return Icons.spa;
      case TrustLevel.trustedUser:
        return Icons.verified_user;
      case TrustLevel.premiumUser:
        return Icons.workspace_premium;
    }
  }

  static String trustLevelIcon(TrustLevel level) => '';
}
