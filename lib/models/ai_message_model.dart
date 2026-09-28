import 'package:harvesthub_app/models/product_model.dart';

class AIMessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<ProductModel>? recommendedProducts;

  AIMessageModel({
    String? id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.recommendedProducts,
  })  : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();
}
