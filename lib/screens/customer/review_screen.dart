import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/cart_item_model.dart';
import '../../models/review_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ReviewScreen extends StatefulWidget {
  final String orderId;
  final List<CartItemModel> items;

  const ReviewScreen({super.key, required this.orderId, required this.items});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final Map<String, int> _ratings = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _submitting = false;
  bool _submitted = false;
  bool _loadingExistingReviews = true;

  final Set<String> _alreadyReviewed = {};

  @override
  void initState() {
    super.initState();
    for (final item in widget.items) {
      _ratings[item.product.id] = 0;
      _controllers[item.product.id] = TextEditingController();
    }
    _checkExistingReviews();
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _checkExistingReviews() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingExistingReviews = false);
      return;
    }

    try {
      for (final item in widget.items) {
        final productId = item.product.id;
        final directReview = await FirebaseFirestore.instance
            .collection('reviews')
            .doc(_reviewDocumentId(widget.orderId, productId))
            .get();
        Map<String, dynamic>? data = directReview.data();

        if (data == null) {
          final legacyReviews = await FirebaseFirestore.instance
              .collection('reviews')
              .where('productId', isEqualTo: productId)
              .get();
          final matchingReview = legacyReviews.docs
              .where((doc) => doc.data()['orderId'] == widget.orderId)
              .firstOrNull;
          data = matchingReview?.data();
        }

        if (data != null && data['customerId'] == uid && mounted) {
          setState(() {
            _alreadyReviewed.add(productId);
            _ratings[productId] = (data?['rating'] as num?)?.toInt() ?? 0;
            _controllers[productId]?.text = data?['comment'] as String? ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking existing reviews: $e');
    } finally {
      if (mounted) setState(() => _loadingExistingReviews = false);
    }
  }

  String _reviewDocumentId(String orderId, String productId) =>
      '${orderId}_$productId';

  Future<void> _submitReviews() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_loadingExistingReviews) return;

    final unrated = widget.items
        .where(
          (i) =>
              !_alreadyReviewed.contains(i.product.id) &&
              (_ratings[i.product.id] ?? 0) == 0,
        )
        .toList();

    if (unrated.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please rate: ${unrated.map((item) => item.product.name).join(', ')}',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final database = FirebaseFirestore.instance;
      final customerName = AuthService().userModel?.fullName ?? 'Customer';
      for (final item in widget.items) {
        final pid = item.product.id;
        if (_alreadyReviewed.contains(pid)) continue;

        final orderRef = database.collection('orders').doc(widget.orderId);
        final productRef = database.collection('products').doc(pid);
        final farmerRef = database
            .collection('farmers')
            .doc(item.product.farmerId);
        final reviewRef = database
            .collection('reviews')
            .doc(_reviewDocumentId(widget.orderId, pid));

        await database.runTransaction((transaction) async {
          final orderSnapshot = await transaction.get(orderRef);
          final productSnapshot = await transaction.get(productRef);
          final farmerSnapshot = await transaction.get(farmerRef);
          final reviewSnapshot = await transaction.get(reviewRef);

          if (!orderSnapshot.exists ||
              orderSnapshot.data()?['customerId'] != uid) {
            throw StateError('This order does not belong to your account.');
          }
          final order = orderSnapshot.data()!;
          final orderStatus = (order['status'] as String? ?? '').toLowerCase();
          if (orderStatus != 'delivered' && orderStatus != 'completed') {
            throw StateError('You can review products after delivery.');
          }
          final orderItems = order['items'];
          final containsProduct =
              orderItems is List &&
              orderItems.whereType<Map>().any(
                (orderItem) => orderItem['productId'] == pid,
              );
          if (!containsProduct || !productSnapshot.exists) {
            throw StateError(
              'This product is not part of the delivered order.',
            );
          }
          if (reviewSnapshot.exists) {
            throw StateError('You have already reviewed this product.');
          }

          final product = productSnapshot.data()!;
          final farmerId = product['farmerId'] as String? ?? '';
          if (farmerId.isEmpty || farmerId != item.product.farmerId) {
            throw StateError(
              'The farmer for this product could not be verified.',
            );
          }

          final rating = _ratings[pid]!;
          final productData = productSnapshot.data()!;
          final farmerData = farmerSnapshot.data() ?? <String, dynamic>{};
          final productCount =
              (productData['ratingCount'] as num?)?.toInt() ?? 0;
          final productTotal =
              (productData['ratingTotal'] as num?)?.toDouble() ?? 0;
          final farmerCount = (farmerData['ratingCount'] as num?)?.toInt() ?? 0;
          final farmerTotal =
              (farmerData['ratingTotal'] as num?)?.toDouble() ?? 0;
          final nextProductCount = productCount + 1;
          final nextProductTotal = productTotal + rating;
          final nextFarmerCount = farmerCount + 1;
          final nextFarmerTotal = farmerTotal + rating;
          final comment = _controllers[pid]?.text.trim() ?? '';
          final review = ReviewModel(
            id: reviewRef.id,
            productId: pid,
            productName: item.product.name,
            orderId: widget.orderId,
            customerId: uid,
            customerName: customerName,
            farmerId: farmerId,
            rating: rating,
            comment: comment,
            createdAt: DateTime.now(),
          );

          transaction.set(reviewRef, review.toMap());
          transaction.set(productRef, {
            'ratingCount': nextProductCount,
            'ratingTotal': nextProductTotal,
            'rating': nextProductTotal / nextProductCount,
            'reviewsCount': nextProductCount,
            'lastReviewId': reviewRef.id,
          }, SetOptions(merge: true));
          transaction.set(farmerRef, {
            'name': farmerData['name'] ?? item.product.farmerName,
            'farmName': farmerData['farmName'] ?? item.product.farmerFarm,
            'ratingCount': nextFarmerCount,
            'ratingTotal': nextFarmerTotal,
            'rating': nextFarmerTotal / nextFarmerCount,
            'reviewCount': nextFarmerCount,
            'reviewsCount': nextFarmerCount,
            'lastReviewId': reviewRef.id,
          }, SetOptions(merge: true));
        });
        if (mounted) setState(() => _alreadyReviewed.add(pid));
      }

      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        final message = e is FirebaseException
            ? e.message ?? e.code
            : e.toString().replaceFirst('Bad state: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not submit review: $message'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Rate Your Order',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 72,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Thank You!',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your review helps other customers discover\nthe best local farm produce.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: const Color(0xFF0D1A13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Back to Order',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.rate_review_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share Your Experience',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Rate the freshness & quality of the products you received',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ...widget.items.map((item) {
            final pid = item.product.id;
            final isReviewed = _alreadyReviewed.contains(pid);
            final currentRating = _ratings[pid] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isReviewed
                      ? AppTheme.primary.withValues(alpha: 0.4)
                      : AppTheme.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item.product.imageUrl.isNotEmpty
                              ? Image.network(
                                  item.product.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) =>
                                      _imgPlaceholder(),
                                )
                              : _imgPlaceholder(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${item.quantity} × Rs. ${item.product.price.toStringAsFixed(0)}  •  ${item.product.category}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isReviewed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline, size: 12, color: AppTheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Reviewed',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Rating',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (starIndex) {
                            final star = starIndex + 1;
                            final filled = star <= currentRating;
                            return GestureDetector(
                              onTap: isReviewed
                                  ? null
                                  : () => setState(() => _ratings[pid] = star),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  filled
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: filled
                                      ? Colors.amber
                                      : AppTheme.textMuted,
                                  size: 34,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _controllers[pid],
                          enabled: !isReviewed,
                          maxLines: 2,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: isReviewed
                                ? 'Your review comment'
                                : 'Describe quality, taste, freshness... (optional)',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                            filled: true,
                            fillColor: AppTheme.surface,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: const Color(0xFF0D1A13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _submitting || _loadingExistingReviews
                  ? null
                  : _submitReviews,
              child: _submitting || _loadingExistingReviews
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF0D1A13),
                      ),
                    )
                  : Text(
                      'Submit Reviews',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      color: AppTheme.surface,
      child: const Icon(Icons.eco_rounded, color: AppTheme.primary, size: 26),
    );
  }
}
