import 'cart_item_model.dart';

class OrderModel {
  final String id;
  final List<CartItemModel> items;
  final double totalAmount;
  final String deliveryAddress;
  final String pickupSlot;
  final String paymentMethod;
  final String status; // 'Processing', 'In Transit', 'Ready for Pickup', 'Delivered', 'Cancelled'
  final DateTime orderDate;
  final String farmerName;
  final String customerName;
  final String customerPhone;
  final String farmerId;
  final String farmerPhone;
  final String? customerId; // Add customerId field

  OrderModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.pickupSlot,
    required this.paymentMethod,
    required this.status,
    required this.orderDate,
    required this.farmerName,
    this.customerName = '',
    this.customerPhone = '',
    this.farmerId = '',
    this.farmerPhone = '',
    this.customerId,
  });

  String get formattedTotal => 'Rs ${totalAmount.toStringAsFixed(0)}';
}
