import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String productId;
  final String productName;
  final String orderId;
  final String customerId;
  final String customerName;
  final String farmerId;      // for farmer profile reviews tab
  final int rating;           // 1–5
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    this.farmerId = '',
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'orderId': orderId,
        'customerId': customerId,
        'customerName': customerName,
        'farmerId': farmerId,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ReviewModel.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final ts = d['createdAt'];
    return ReviewModel(
      id: doc.id,
      productId: d['productId'] as String? ?? '',
      productName: d['productName'] as String? ?? '',
      orderId: d['orderId'] as String? ?? '',
      customerId: d['customerId'] as String? ?? '',
      customerName: d['customerName'] as String? ?? 'Customer',
      farmerId: d['farmerId'] as String? ?? '',
      rating: (d['rating'] as num?)?.toInt() ?? 0,
      comment: d['comment'] as String? ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
