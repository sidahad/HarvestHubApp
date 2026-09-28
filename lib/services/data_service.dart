import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/farmer_model.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/notification_model.dart';
import '../models/ai_message_model.dart';
import '../models/pickup_slot_model.dart';
import 'notification_service.dart';
import 'gamification_service.dart';

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal() {
    _initSampleData();
  }

  // Collections
  List<CategoryModel> categories = [];
  List<FarmerModel> farmers = [];
  List<ProductModel> products = [];
  List<CartItemModel> cart = [];
  List<OrderModel> orders = [];
  List<NotificationModel> notifications = [];
  List<AIMessageModel> aiMessages = [];
  List<PickupSlotModel> pickupSlots = [];
  Set<String> favoriteProductIds = {};

  // Selected State
  String selectedCategory = 'All';
  String searchQuery = '';
  String locationFilter = '';
  double? customerLatitude;
  double? customerLongitude;
  String? productNameFilter;
  String? farmerNameFilter;
  double maxDistanceKm = 50.0;
  String selectedMarket = 'All Markets';
  double? priceLimit;
  String priceFilter = 'Any price';
  String selectedPickupSlot = '';
  String selectedDeliveryAddress = '';

  // ==================== HARVEST AI (Gemini) CONFIG ====================
  // Pass your key at build/run time, e.g.:
  //   flutter run --dart-define=GEMINI_API_KEY=your_key_here
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String _geminiModel = 'gemini-2.0-flash';
  static String get _geminiEndpoint =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_geminiApiKey';

  static const String _harvestAISystemPrompt =
      'You are HarvestAI, a friendly botanical specialist assistant inside the '
      'HarvestHub farm-to-table produce app. Give short, practical, helpful '
      'answers about fresh produce, seasonal harvests, recipes, organic '
      'verification, local farmer prices, and pickups. Keep replies concise '
      '(2-5 sentences) and use the occasional relevant emoji, matching the '
      'friendly tone of the app.';

  bool isAILoading = false;

  Future<void> loadCatalog() async {
    final database = FirebaseFirestore.instance;
    final categorySnapshot = await database.collection('categories').get();
    final farmerSnapshot = await database.collection('farmers').get();
    final productSnapshot = await database.collection('products').get();

    final loadedCategories = categorySnapshot.docs
        .map((doc) {
          final data = doc.data();
          final name = data['name'] as String? ?? '';
          return CategoryModel(
            id: doc.id,
            name: name,
            iconEmoji: (data['icon'] as String?)?.isNotEmpty == true
                ? data['icon'] as String
                : _getEmojiForCategory(name),
            image: data['image'] as String? ?? '',
            itemCount: (data['itemCount'] as num?)?.toInt() ?? 0,
          );
        })
        .where((category) => category.name.isNotEmpty)
        .toList();

    // Only use real Firestore data - no dummy data
    categories = loadedCategories;

    final Set<String> currentFollowed = Set<String>.from(_followedFarmerIds);

    final loadedFarmers = farmerSnapshot.docs
        .map((doc) {
          final data = doc.data();
          final defaultLat = 31.5204 + ((doc.id.hashCode.abs() % 40) - 20) * 0.004;
          final defaultLng = 74.3584 + (((doc.id.hashCode.abs() ~/ 40) % 40) - 20) * 0.004;
          return FarmerModel(
            id: doc.id,
            name: data['name'] as String? ?? '',
            farmName: data['farmName'] as String? ?? '',
            location: data['location'] as String? ?? '',
            latitude: (data['latitude'] as num?)?.toDouble() ?? defaultLat,
            longitude: (data['longitude'] as num?)?.toDouble() ?? defaultLng,
            marketName: data['marketName'] as String? ?? '',
            marketHours: data['marketHours'] as String? ?? '',
            distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
            rating: (data['rating'] as num?)?.toDouble() ?? 0,
            reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
            avatarUrl: data['avatarUrl'] as String? ?? data['profilePic'] as String? ?? '',
            bio: data['bio'] as String? ?? '',
            isVerified: data['isVerified'] as bool? ?? false,
            followerCount: (data['followerCount'] as num?)?.toInt() ?? 0,
            totalProducts: (data['totalProducts'] as num?)?.toInt() ?? 0,
            isFollowing: currentFollowed.contains(doc.id),
          );
        })
        .where((farmer) => farmer.name.isNotEmpty)
        .toList();

    // Build farmers map from both farmers collection and users collection
    final Map<String, FarmerModel> farmerMap = {
      for (final f in loadedFarmers) f.id: f,
    };

    final allUsers = await database.collection('users').get();
    for (final doc in allUsers.docs) {
      final data = doc.data();
      final role = (data['role'] as String? ?? '').toLowerCase();
      if (role != 'farmer') continue;

      final userVerified = data['isVerified'] == true;
      final name = data['fullName'] as String? ?? '';
      if (name.isEmpty) continue;

      final userPic = (data['profilePic'] as String? ?? data['photoUrl'] as String? ?? data['photoURL'] as String? ?? '').trim();
      final defaultLat = 31.5204 + ((doc.id.hashCode.abs() % 40) - 20) * 0.004;
      final defaultLng = 74.3584 + (((doc.id.hashCode.abs() ~/ 40) % 40) - 20) * 0.004;

      if (farmerMap.containsKey(doc.id)) {
        final existing = farmerMap[doc.id]!;
        final finalAvatar = (existing.avatarUrl.trim().isNotEmpty && !existing.avatarUrl.contains('unsplash.com'))
            ? existing.avatarUrl
            : (userPic.isNotEmpty ? userPic : existing.avatarUrl);

        farmerMap[doc.id] = FarmerModel(
          id: existing.id,
          name: existing.name.isNotEmpty ? existing.name : name,
          farmName: existing.farmName.isNotEmpty ? existing.farmName : (data['farmName'] as String? ?? '$name Farm'),
          location: existing.location.isNotEmpty ? existing.location : (data['address'] as String? ?? ''),
          latitude: existing.latitude ?? defaultLat,
          longitude: existing.longitude ?? defaultLng,
          marketName: existing.marketName.isNotEmpty ? existing.marketName : (data['marketName'] as String? ?? ''),
          marketHours: existing.marketHours.isNotEmpty ? existing.marketHours : (data['marketHours'] as String? ?? ''),
          city: existing.city,
          area: existing.area,
          distanceKm: existing.distanceKm,
          rating: existing.rating,
          reviewCount: existing.reviewCount,
          avatarUrl: finalAvatar,
          bio: existing.bio.isNotEmpty ? existing.bio : (data['bio'] as String? ?? ''),
          isVerified: userVerified || existing.isVerified,
          followerCount: existing.followerCount,
          totalProducts: existing.totalProducts,
          isFollowing: currentFollowed.contains(existing.id),
        );
      } else {
        farmerMap[doc.id] = FarmerModel(
          id: doc.id,
          name: name,
          farmName: data['farmName'] as String? ?? '$name Farm',
          location: data['address'] as String? ?? '',
          latitude: (data['latitude'] as num?)?.toDouble() ?? defaultLat,
          longitude: (data['longitude'] as num?)?.toDouble() ?? defaultLng,
          marketName: data['marketName'] as String? ?? '',
          marketHours: data['marketHours'] as String? ?? '',
          distanceKm: 0,
          rating: 4.8,
          reviewCount: 0,
          avatarUrl: userPic,
          bio: data['bio'] as String? ?? '',
          isVerified: userVerified,
          followerCount: (data['followerCount'] as num?)?.toInt() ?? 0,
          totalProducts: 0,
          isFollowing: currentFollowed.contains(doc.id),
        );
      }
    }

    farmers = farmerMap.values.toList();

    final loadedProducts = productSnapshot.docs
        .map((doc) {
          final data = doc.data();
          return ProductModel(
            id: doc.id,
            title: data['title'] as String? ?? '',
            category: data['category'] as String? ?? '',
            price: (data['price'] as num?)?.toDouble() ?? 0,
            unit: data['unit'] as String? ?? 'kg',
            imageUrl: data['imageUrl'] as String? ?? '',
            stock: (data['stock'] as num?)?.toInt() ?? 0,
            farmerId: data['farmerId'] as String? ?? '',
            farmerName: data['farmerName'] as String? ?? '',
            farmerPhone: data['farmerPhone'] as String? ?? '',
            farmerFarm: data['farmerFarm'] as String? ?? '',
            rating: (data['rating'] as num?)?.toDouble() ?? 4.8,
            distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 4.5,
            marketName: data['marketName'] as String? ?? '',
            description: data['description'] as String? ?? '',
            isOrganic: data['isOrganic'] as bool? ?? true,
            freshnessScore: (data['freshnessScore'] as num?)?.toInt() ?? 95,
            priceInsight:
                data['priceInsight'] as String? ?? 'Direct from local farm',
            reviewsCount: (data['reviewsCount'] as num?)?.toInt() ?? 10,
          );
        })
        .where((product) => product.title.isNotEmpty)
        .toList();

    // Only use real Firestore products - no dummy data
    products = loadedProducts;

    _applyFavoritesToProducts();
    notifyListeners();
  }

  String _getEmojiForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('fruit')) return '';
    if (lower.contains('veg')) return '';
    if (lower.contains('dairy') || lower.contains('milk')) return '';
    if (lower.contains('grain') ||
        lower.contains('wheat') ||
        lower.contains('atta')) {
      return '';
    }
    if (lower.contains('honey') || lower.contains('jam')) return '';
    if (lower.contains('organic') || lower.contains('herb')) return '';
    if (lower.contains('egg')) return '';
    return '';
  }

  void _applyFavoritesToProducts() {
    for (final p in products) {
      p.isFavorite = favoriteProductIds.contains(p.id);
    }
  }

  void _initSampleData() {
    // Initialize with empty lists - data will be loaded from Firestore
    categories = [];
    farmers = [];
    products = [];
    cart = [];
    orders = [];
    notifications = [];

    // HarvestAI initial chat
    aiMessages = [
      AIMessageModel(
        text:
            'Hello! I am HarvestAI, your personal farm assistant. How can I help you today? Ask me about seasonal crops, healthy recipes, or local farmer prices!',
        isUser: false,
      ),
    ];
  }

  // Filtered products list getter
  List<ProductModel> get filteredProducts {
    final farmersById = {for (final farmer in farmers) farmer.id: farmer};
    return products.where((p) {
      final farmer = farmersById[p.farmerId];
      final matchesCategory =
          selectedCategory == 'All' ||
          p.category.toLowerCase() == selectedCategory.toLowerCase();
      final matchesSearch =
          searchQuery.isEmpty ||
          p.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.farmerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(searchQuery.toLowerCase());

      // Product name filter from advanced search
      final matchesProductName =
          productNameFilter == null ||
          productNameFilter!.isEmpty ||
          p.title.toLowerCase().contains(productNameFilter!.toLowerCase());

      // Farmer name filter from advanced search
      final matchesFarmerName =
          farmerNameFilter == null ||
          farmerNameFilter!.isEmpty ||
          p.farmerName.toLowerCase().contains(
            farmerNameFilter!.toLowerCase(),
          ) ||
          p.farmerFarm.toLowerCase().contains(farmerNameFilter!.toLowerCase());

      final normalizedLocationFilter = locationFilter.trim().toLowerCase();
      final searchableLocation = [
        p.marketName,
        p.farmerName,
        p.farmerFarm,
        farmer?.farmName ?? '',
        farmer?.location ?? '',
        farmer?.marketName ?? '',
      ].join(' ').toLowerCase();
      final matchesLocation =
          normalizedLocationFilter.isEmpty ||
          searchableLocation.contains(normalizedLocationFilter);

      final matchesPrice =
          priceLimit == null ||
          priceFilter == 'Any price' ||
          (priceFilter == 'Less than' && p.price <= priceLimit!) ||
          (priceFilter == 'Greater than' && p.price >= priceLimit!);
      final distanceKm = farmer == null
          ? null
          : distanceFromCustomerToFarmer(farmer);
      final matchesDistance = (distanceKm ?? p.distanceKm) <= maxDistanceKm;
      final farmerMarket = farmer == null
          ? ''
          : farmer.marketName.isNotEmpty
          ? farmer.marketName
          : farmer.farmName;
      final matchesMarket =
          selectedMarket == 'All Markets' ||
          p.marketName == selectedMarket ||
          farmerMarket == selectedMarket;

      return matchesCategory &&
          matchesSearch &&
          matchesProductName &&
          matchesFarmerName &&
          matchesLocation &&
          matchesDistance &&
          matchesMarket &&
          matchesPrice;
    }).toList();
  }

  // Wishlist products
  List<ProductModel> get wishlistProducts {
    return products
        .where((p) => p.isFavorite || favoriteProductIds.contains(p.id))
        .toList();
  }

  Future<void> loadWishlistForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      favoriteProductIds.clear();
      _applyFavoritesToProducts();
      notifyListeners();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc('current')
          .get();

      if (doc.exists && doc.data() != null) {
        final raw = doc.data()!['productIds'];
        if (raw is List) {
          favoriteProductIds = raw.map((e) => e.toString()).toSet();
        }
      }
      _applyFavoritesToProducts();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    }
  }

  final Set<String> _followedFarmerIds = <String>{};
  Set<String> get followedFarmerIds => Set.unmodifiable(_followedFarmerIds);
  bool isFarmerFollowed(String farmerId) => _followedFarmerIds.contains(farmerId);

  // Load followed farmers from SharedPreferences & Firestore
  Future<void> loadFollowedFarmersForCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList('harvesthub_followed_farmers') ?? [];
      _followedFarmerIds.addAll(cached);
    } catch (_) {}

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('followed_farmers')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (final doc in snapshot.docs) {
          final fid = doc.data()['farmerId'] as String?;
          if (fid != null && fid.isNotEmpty) {
            _followedFarmerIds.add(fid);
          }
        }
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('harvesthub_followed_farmers', _followedFarmerIds.toList());
        } catch (_) {}

        debugPrint(' Loaded ${_followedFarmerIds.length} followed farmers from Firestore');
      } catch (e) {
        debugPrint(' Error loading followed farmers from Firestore: $e');
      }
    }

    for (var farmer in farmers) {
      farmer.isFollowing = _followedFarmerIds.contains(farmer.id);
    }
    notifyListeners();
  }

  Future<void> _syncWishlistToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc('current')
          .set({
            'productIds': favoriteProductIds.toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error syncing wishlist: $e');
    }
  }

  // Notifications loader & sync
  Future<void> loadNotificationsForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      notifications.clear();
      notifyListeners();
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        // Build initial notifications for this user: past orders + welcome/deals
        final initialList = <NotificationModel>[];

        if (orders.isNotEmpty) {
          for (final order in orders) {
            initialList.add(
              NotificationModel(
                id: 'notif_order_${order.id}',
                title: order.status == 'Delivered'
                    ? 'Order Delivered! '
                    : 'Order Confirmed! ',
                message:
                    'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id} placed with ${order.items.length} item(s) for ${order.formattedTotal}.',
                timeAgo: 'Recently',
                type: 'order',
                isRead: false,
                createdAt: order.orderDate,
              ),
            );
          }
        }

        initialList.addAll([
          NotificationModel(
            id: 'notif_restock_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Fresh Harvest Alert ',
            message:
                'Fresh organic strawberries and seasonal farm produce are now available from local farmers!',
            timeAgo: 'Recently',
            type: 'restock',
            isRead: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          NotificationModel(
            id: 'notif_promo_${DateTime.now().millisecondsSinceEpoch + 1}',
            title: '20% OFF Fresh Produce ',
            message:
                'Use code HARVEST20 to get 20% discount on all fresh dairy and farm-fresh organic items.',
            timeAgo: 'Yesterday',
            type: 'promo',
            isRead: true,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          NotificationModel(
            id: 'notif_system_${DateTime.now().millisecondsSinceEpoch + 2}',
            title: 'Welcome to HarvestHub ',
            message:
                'Support local farmers, enjoy certified fresh harvests, and experience transparent farm-to-table shopping.',
            timeAgo: '2 days ago',
            type: 'system',
            isRead: true,
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ]);

        notifications = initialList;
        notifyListeners();

        // Persist seed notifications in Firestore so they stay permanently
        final batch = FirebaseFirestore.instance.batch();
        for (final notif in initialList) {
          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .doc(notif.id);
          batch.set(docRef, notif.toMap());
        }
        await batch.commit();
        return;
      }

      notifications = snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.id, doc.data());
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications for user: $e');
    }
  }

  Future<void> _saveNotificationToFirestore(NotificationModel notif) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notif.id)
          .set(notif.toMap());
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    bool isRead = false,
  }) async {
    final notif = NotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      timeAgo: 'Just now',
      type: type,
      isRead: isRead,
      createdAt: DateTime.now(),
    );

    notifications.insert(0, notif);
    notifyListeners();
    await _saveNotificationToFirestore(notif);
  }

  // Followed farmers
  List<FarmerModel> get followedFarmers {
    return farmers.where((f) => f.isFollowing).toList();
  }

  // Totals
  double get cartSubtotal {
    return cart.fold(0.0, (total, item) => total + item.totalPrice);
  }

  double get deliveryFee => cart.isEmpty ? 0.0 : 150.0;
  double get cartTotal => cartSubtotal + deliveryFee;

  Future<void> loadCartForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc('current')
          .get();

      if (!doc.exists || doc.data() == null) return;
      final rawItems = doc.data()!['items'];
      if (rawItems is! List) return;

      final loaded = <CartItemModel>[];
      for (final raw in rawItems) {
        if (raw is! Map) continue;
        final productId = raw['productId'] as String? ?? '';
        final quantity = (raw['quantity'] as num?)?.toInt() ?? 1;
        if (productId.isEmpty || quantity <= 0) continue;

        final product = products.firstWhere(
          (p) => p.id == productId,
          orElse: () => ProductModel(
            id: productId,
            title: raw['title'] as String? ?? 'Farm Produce',
            category: raw['category'] as String? ?? 'General',
            price: (raw['price'] as num?)?.toDouble() ?? 0.0,
            unit: raw['unit'] as String? ?? 'kg',
            imageUrl: raw['imageUrl'] as String? ?? '',
            stock: (raw['stock'] as num?)?.toInt() ?? 10,
            farmerId: raw['farmerId'] as String? ?? '',
            farmerName: raw['farmerName'] as String? ?? 'Harvest Farmer',
            farmerPhone: '',
            farmerFarm: '',
            rating: 5.0,
            distanceKm: 0,
            marketName: '',
            description: '',
          ),
        );
        loaded.add(CartItemModel(product: product, quantity: quantity));
      }
      cart = loaded;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart for user: $e');
    }
  }

  Future<void> _syncCartToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final cartData = cart
          .map(
            (item) => {
              'productId': item.product.id,
              'quantity': item.quantity,
              'title': item.product.title,
              'price': item.product.price,
              'unit': item.product.unit,
              'imageUrl': item.product.imageUrl,
              'category': item.product.category,
              'farmerId': item.product.farmerId,
              'farmerName': item.product.farmerName,
              'stock': item.product.stock,
            },
          )
          .toList();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc('current')
          .set({'items': cartData, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error syncing cart: $e');
    }
  }

  Future<void> loadOrdersForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: user.uid)
        .get();

    final loadedOrders =
        snapshot.docs.map(_orderFromDocument).whereType<OrderModel>().toList()
          ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

    orders = loadedOrders;
    notifyListeners();
  }

  Future<void> loadOrdersForStaff() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final role = profile.data()?['role'];
    if (role != 'Farmer' && role != 'Admin') return;

    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .get();
    final loadedOrders =
        snapshot.docs.map(_orderFromDocument).whereType<OrderModel>().toList()
          ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
    orders = loadedOrders;
    notifyListeners();
  }

  OrderModel? _orderFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final rawItems = data['items'];
    if (rawItems is! List) return null;

    final items = rawItems.whereType<Map<String, dynamic>>().map((item) {
      final product = products.firstWhere(
        (candidate) => candidate.id == item['productId'],
        orElse: () => ProductModel(
          id: item['productId'] as String? ?? 'unknown',
          title: item['name'] as String? ?? 'Product',
          category: item['category'] as String? ?? 'Other',
          price: (item['price'] as num?)?.toDouble() ?? 0,
          unit: item['unit'] as String? ?? 'unit',
          imageUrl: item['imageUrl'] as String? ?? '',
          stock: 0,
          farmerId: item['farmerId'] as String? ?? '',
          farmerName: item['farmerName'] as String? ?? 'Farmer',
          farmerPhone: item['farmerPhone'] as String? ?? '',
          farmerFarm: '',
          rating: 0,
          distanceKm: 0,
          marketName: '',
          description: '',
        ),
      );
      return CartItemModel(
        product: product,
        quantity: (item['quantity'] as num?)?.toInt() ?? 1,
      );
    }).toList();

    final createdAt = data['createdAt'];
    final orderDate = createdAt is Timestamp
        ? createdAt.toDate()
        : DateTime.now();
    return OrderModel(
      id: document.id,
      items: items,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      deliveryAddress: data['deliveryAddress'] as String? ?? '',
      pickupSlot: data['pickupSlot'] as String? ?? '',
      paymentMethod: data['paymentMethod'] as String? ?? '',
      status: data['status'] as String? ?? 'Processing',
      orderDate: orderDate,
      farmerName: data['farmerName'] as String? ?? 'HarvestHub Partner Farm',
      customerName: data['customerName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
      farmerId: data['farmerId'] as String? ?? '',
      farmerPhone: () {
        // Try top-level field first (new orders), then fall back to
        // items[0].farmerPhone (old orders that were saved without top-level field)
        final topLevel = data['farmerPhone'] as String? ?? '';
        if (topLevel.isNotEmpty) return topLevel;
        final itemsList = data['items'] as List<dynamic>? ?? [];
        if (itemsList.isNotEmpty) {
          final firstItem = itemsList.first as Map<String, dynamic>? ?? {};
          return firstItem['farmerPhone'] as String? ?? '';
        }
        return '';
      }(),
    );
  }

  // Actions
  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) throw 'Category name is required.';
    if (categories.any(
      (category) => category.name.toLowerCase() == normalized.toLowerCase(),
    )) {
      throw 'This category already exists.';
    }

    final doc = FirebaseFirestore.instance.collection('categories').doc();
    await doc.set({
      'name': normalized,
      'icon': '',
      'image': '',
      'itemCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    categories.add(
      CategoryModel(
        id: doc.id,
        name: normalized,
        iconEmoji: '',
        image: '',
        itemCount: 0,
      ),
    );
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  double? distanceFromCustomerToFarmer(FarmerModel farmer) {
    final latitude = customerLatitude;
    final longitude = customerLongitude;
    final farmerLatitude = farmer.latitude;
    final farmerLongitude = farmer.longitude;
    if (latitude == null ||
        longitude == null ||
        farmerLatitude == null ||
        farmerLongitude == null) {
      return null;
    }

    return Geolocator.distanceBetween(
          latitude,
          longitude,
          farmerLatitude,
          farmerLongitude,
        ) /
        1000;
  }

  void setCustomerLocation({
    required double latitude,
    required double longitude,
  }) {
    customerLatitude = latitude;
    customerLongitude = longitude;
    notifyListeners();
  }

  void updateFilters({
    required double distance,
    required String market,
    required String category,
    double? price,
    String priceMode = 'Any price',
    String? productName,
    String? farmerName,
    String? location,
  }) {
    maxDistanceKm = distance;
    selectedMarket = market;
    selectedCategory = category;
    priceLimit = price;
    priceFilter = priceMode;
    productNameFilter = productName;
    farmerNameFilter = farmerName;
    if (location != null) locationFilter = location;
    notifyListeners();
  }

  void resetFilters() {
    selectedCategory = 'All';
    searchQuery = '';
    locationFilter = '';
    productNameFilter = null;
    farmerNameFilter = null;
    maxDistanceKm = 50.0;
    selectedMarket = 'All Markets';
    priceLimit = null;
    priceFilter = 'Any price';
    customerLatitude = null;
    customerLongitude = null;
    notifyListeners();
  }

  void toggleFavorite(String productId) {
    final isFav = favoriteProductIds.contains(productId);
    if (isFav) {
      favoriteProductIds.remove(productId);
    } else {
      favoriteProductIds.add(productId);
    }

    final index = products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      products[index].isFavorite = !isFav;
    }

    notifyListeners();
    _syncWishlistToFirestore();
  }

  void toggleFollowFarmer(String farmerId) async {
    final index = farmers.indexWhere((f) => f.id == farmerId);
    final wasFollowing = _followedFarmerIds.contains(farmerId) ||
        (index != -1 && farmers[index].isFollowing);
    final newFollowState = !wasFollowing;

    // 1. Update in-memory set & SharedPreferences immediately
    if (newFollowState) {
      _followedFarmerIds.add(farmerId);
    } else {
      _followedFarmerIds.remove(farmerId);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('harvesthub_followed_farmers', _followedFarmerIds.toList());
    } catch (_) {}

    // 2. Update in-memory farmer model
    if (index != -1) {
      farmers[index] = FarmerModel(
        id: farmers[index].id,
        name: farmers[index].name,
        farmName: farmers[index].farmName,
        location: farmers[index].location,
        distanceKm: farmers[index].distanceKm,
        latitude: farmers[index].latitude,
        longitude: farmers[index].longitude,
        marketName: farmers[index].marketName,
        marketHours: farmers[index].marketHours,
        city: farmers[index].city,
        area: farmers[index].area,
        rating: farmers[index].rating,
        reviewCount: farmers[index].reviewCount,
        avatarUrl: farmers[index].avatarUrl,
        bio: farmers[index].bio,
        isVerified: farmers[index].isVerified,
        followerCount: newFollowState
            ? farmers[index].followerCount + 1
            : (farmers[index].followerCount > 0
                ? farmers[index].followerCount - 1
                : 0),
        isFollowing: newFollowState,
      );
    }

    // Notify all UI listeners immediately
    notifyListeners();

    // 3. Persist to Firestore
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid ?? 'guest_user';
    final docId = '${uid}_$farmerId';

    if (newFollowState) {
      try {
        await FirebaseFirestore.instance
            .collection('followed_farmers')
            .doc(docId)
            .set({
              'userId': uid,
              'farmerId': farmerId,
              'farmerName': index != -1 ? farmers[index].name : '',
              'farmName': index != -1 ? farmers[index].farmName : '',
              'followedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        FirebaseFirestore.instance
            .collection('farmers')
            .doc(farmerId)
            .set({'followerCount': FieldValue.increment(1)}, SetOptions(merge: true))
            .catchError((_) {});

        FirebaseFirestore.instance
            .collection('users')
            .doc(farmerId)
            .set({'followerCount': FieldValue.increment(1)}, SetOptions(merge: true))
            .catchError((_) {});

        debugPrint(' Followed farmer: ${index != -1 ? farmers[index].name : farmerId}');
      } catch (e) {
        debugPrint(' Error following farmer: $e');
      }
    } else {
      try {
        await FirebaseFirestore.instance
            .collection('followed_farmers')
            .doc(docId)
            .delete();

        FirebaseFirestore.instance
            .collection('farmers')
            .doc(farmerId)
            .set({'followerCount': FieldValue.increment(-1)}, SetOptions(merge: true))
            .catchError((_) {});

        FirebaseFirestore.instance
            .collection('users')
            .doc(farmerId)
            .set({'followerCount': FieldValue.increment(-1)}, SetOptions(merge: true))
            .catchError((_) {});

        debugPrint(' Unfollowed farmer: ${index != -1 ? farmers[index].name : farmerId}');
      } catch (e) {
        debugPrint(' Error unfollowing farmer: $e');
      }
    }
  }

  void addToCart(ProductModel product, {int qty = 1}) {
    final existingIndex = cart.indexWhere((c) => c.product.id == product.id);
    if (existingIndex != -1) {
      cart[existingIndex].quantity += qty;
    } else {
      cart.add(CartItemModel(product: product, quantity: qty));
    }
    notifyListeners();
    _syncCartToFirestore();
  }

  void addMultipleToCart(List<ProductModel> items) {
    for (final item in items) {
      final existingIndex = cart.indexWhere((c) => c.product.id == item.id);
      if (existingIndex != -1) {
        cart[existingIndex].quantity += 1;
      } else {
        cart.add(CartItemModel(product: item, quantity: 1));
      }
    }
    notifyListeners();
    _syncCartToFirestore();
  }

  void updateCartQuantity(String productId, int delta) {
    final index = cart.indexWhere((c) => c.product.id == productId);
    if (index != -1) {
      cart[index].quantity += delta;
      if (cart[index].quantity <= 0) {
        cart.removeAt(index);
      }
      notifyListeners();
      _syncCartToFirestore();
    }
  }

  void removeFromCart(String productId) {
    cart.removeWhere((c) => c.product.id == productId);
    notifyListeners();
    _syncCartToFirestore();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
    _syncCartToFirestore();
  }

  void clearCartMemoryOnly() {
    cart.clear();
    notifyListeners();
  }

  Future<List<OrderModel>> createOrders({
    required String customerName,
    required String customerPhone,
    required String address,
    required String slot,
    required String paymentMethod,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw 'Please log in before placing an order.';
    }
    if (cart.isEmpty) {
      throw 'Your cart is empty.';
    }
    final unavailable = cart
        .where((item) => item.quantity > item.product.stock)
        .toList();
    if (unavailable.isNotEmpty) {
      throw '${unavailable.first.product.name} does not have enough stock.';
    }

    final groupedItems = <String, List<CartItemModel>>{};
    for (final item in cart) {
      groupedItems.putIfAbsent(item.product.farmerId, () => []).add(item);
    }

    final parentOrderId = 'HH-${DateTime.now().millisecondsSinceEpoch}';
    final farmerOrders = <OrderModel>[];
    final deliveryFeePerFarmer = 150.0 / groupedItems.length;

    for (final entry in groupedItems.entries) {
      final farmerItems = entry.value;
      final farmerSubtotal = farmerItems.fold<double>(
        0,
        (total, item) => total + item.totalPrice,
      );
      final order = OrderModel(
        id: '$parentOrderId-${entry.key}',
        items: List.from(farmerItems),
        totalAmount: farmerSubtotal + deliveryFeePerFarmer,
        deliveryAddress: address,
        pickupSlot: slot,
        paymentMethod: paymentMethod,
        status: 'Processing',
        orderDate: DateTime.now(),
        farmerName: farmerItems.first.product.farmerName,
        customerName: customerName,
        customerPhone: customerPhone,
        farmerId: entry.key,
        farmerPhone: farmerItems.first.product.farmerPhone,
      );

      await FirebaseFirestore.instance.collection('orders').doc(order.id).set({
        'parentOrderId': parentOrderId,
        'customerId': user.uid,
        'customerName': order.customerName,
        'customerPhone': order.customerPhone,
        'farmerId': order.farmerId,
        'productIds': order.items.map((item) => item.product.id).toList(),
        'items': order.items
            .map(
              (item) => {
                'productId': item.product.id,
                'name': item.product.name,
                'category': item.product.category,
                'price': item.product.price,
                'quantity': item.quantity,
                'unit': item.product.unit,
                'imageUrl': item.product.imageUrl,
                'farmerId': item.product.farmerId,
                'farmerName': item.product.farmerName,
                'farmerPhone': item.product.farmerPhone,
              },
            )
            .toList(),
        'subtotal': farmerSubtotal,
        'deliveryFee': deliveryFeePerFarmer,
        'totalAmount': order.totalAmount,
        'deliveryAddress': order.deliveryAddress,
        'pickupSlot': order.pickupSlot,
        'paymentMethod': order.paymentMethod,
        'status': order.status,
        'farmerName': order.farmerName,
        'farmerPhone': order.farmerPhone,
        'createdAt': Timestamp.fromDate(order.orderDate),
      });

      // Send push notification to farmer about new order
      try {
        final notificationService = NotificationService();
        await notificationService.sendNewOrderNotification(
          farmerId: entry.key,
          orderId: order.id,
          customerName: customerName,
          totalAmount: order.totalAmount,
        );
      } catch (e) {
        debugPrint('Error sending new order notification: $e');
      }

      farmerOrders.add(order);
    }

    orders.insertAll(0, farmerOrders.reversed);
    cart.clear();
    _syncCartToFirestore();

    // Add notification
    final orderNotif = NotificationModel(
      id: 'notif_order_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Order Confirmed! ',
      message:
          '${farmerOrders.length} farmer order${farmerOrders.length == 1 ? '' : 's'} placed successfully.',
      timeAgo: 'Just now',
      type: 'order',
      isRead: false,
      createdAt: DateTime.now(),
    );
    notifications.insert(0, orderNotif);
    _saveNotificationToFirestore(orderNotif);

    notifyListeners();
    return farmerOrders;
  }

  Future<void> markAllNotificationsRead() async {
    for (var n in notifications) {
      n.isRead = true;
    }
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications read: $e');
    }
  }

  Future<void> markNotificationRead(String id) async {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifications[idx].isRead = true;
      notifyListeners();
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(id)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    notifications.removeWhere((n) => n.id == id);
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    notifications.clear();
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }

  Future<void> restoreNotification(
    NotificationModel notif, {
    int index = 0,
  }) async {
    if (index >= 0 && index <= notifications.length) {
      notifications.insert(index, notif);
    } else {
      notifications.add(notif);
    }
    notifyListeners();
    await _saveNotificationToFirestore(notif);
  }

  void clearUserDataOnLogout() {
    cart.clear();
    orders.clear();
    favoriteProductIds.clear();
    for (final p in products) {
      p.isFavorite = false;
    }
    notifications.clear();
    notifyListeners();
  }

  // AI Assistant reply logic — backed by intelligent local analysis & Gemini API with live app context.
  Future<void> sendAIMessage(String text) async {
    if (text.trim().isEmpty) return;

    aiMessages.add(AIMessageModel(text: text.trim(), isUser: true));
    isAILoading = true;
    notifyListeners();

    // Small natural thinking delay
    await Future.delayed(const Duration(milliseconds: 400));

    if (_geminiApiKey.isNotEmpty) {
      try {
        final response = await _callGeminiForHarvestAI();
        aiMessages.add(AIMessageModel(text: response, isUser: false));
        isAILoading = false;
        notifyListeners();
        return;
      } catch (e) {
        debugPrint(' HarvestAI (Gemini) fallback to local engine: $e');
      }
    }

    // Intelligent local knowledge engine fallback
    final response = _generateIntelligentHarvestAIResponse(text);
    aiMessages.add(AIMessageModel(text: response, isUser: false));
    isAILoading = false;
    notifyListeners();
  }

  String _buildHarvestAIDynamicContext() {
    final farmersSummary = farmers.map((f) => "${f.name} (Farm: ${f.farmName}, Location: ${f.location}, Rating: ${f.rating}, Followers: ${f.followerCount})").join('; ');
    final productsSummary = products.map((p) => "${p.title} (Price: Rs. ${p.price}/${p.unit}, Category: ${p.category}, Farmer: ${p.farmerName}, Stock: ${p.stock})").join('; ');
    return "LIVE APP DATA:\n• Total Registered Farmers: ${farmers.length} ($farmersSummary)\n• Total Available Products: ${products.length} ($productsSummary)\n• Categories: ${categories.map((c) => c.name).join(', ')}";
  }

  String _generateIntelligentHarvestAIResponse(String query) {
    final q = query.toLowerCase().trim();
    final totalFarmers = farmers.length;
    final totalProducts = products.length;
    final totalCategories = categories.length;

    // 1. Questions about Farmers / Kisans
    if (q.contains('farmer') || q.contains('kisan') || q.contains('farmers') || q.contains('kitne farmer')) {
      if (farmers.isEmpty) {
        return "HarvestHub par verified local farmers registered hain jo 100% fresh aur chemical-free organic produce direct farms se provide karte hain!";
      }
      final farmerList = farmers.map((f) => "${f.name} (${f.farmName})").take(5).join('\n• ');
      return "🌾 **HarvestHub Registered Farmers:**\nIs waqt hamare platform par kul **$totalFarmers verified farmers** active hain:\n• $farmerList\n\nAap kisi bhi farmer ki profile open karke unhe **Follow** kar sakte hain taake unki taza harvest ke alerts aapko miltay rahein!";
    }

    // 2. Questions about Products / Inventory / Stock
    if (q.contains('product') || q.contains('cheez') || q.contains('items') || q.contains('stock') || q.contains('kitni product') || q.contains('total product')) {
      if (products.isEmpty) {
        return "HarvestHub par mukhtalif fresh categories mein produce available hai jaise Fruits, Vegetables, Dairy, Grains, aur Honey!";
      }
      final productList = products.map((p) => "${p.title} (Rs. ${p.price.toStringAsFixed(0)}/${p.unit})").take(6).join('\n• ');
      return "🍎 **HarvestHub Fresh Inventory:**\nIs waqt platform par kul **$totalProducts fresh items** ($totalCategories categories) available hain:\n• $productList\n\nAap search bar ya categories se apni pasand ki product select kar sakte hain.";
    }

    // 3. Questions about Cheap / Sasta / Lowest Price / Comparison
    if (q.contains('cheap') || q.contains('sasta') || q.contains('sasti') || q.contains('kam rate') || q.contains('lowest') || q.contains('discount') || q.contains('best price')) {
      if (products.isNotEmpty) {
        final sorted = List<ProductModel>.from(products)..sort((a, b) => a.price.compareTo(b.price));
        final top3 = sorted.take(4).map((p) => "• **${p.title}**: Rs. ${p.price.toStringAsFixed(0)}/${p.unit} (by ${p.farmerName})").join('\n');
        return "💰 **Best & Cheapest Farm Rates:**\nHarvestHub par direct farmer-to-customer model hone ki wajah se koi middlemen commission nahi hai!\n\nSabse munasib rates wali products:\n$top3\n\nAap directly in farmers se buy karke extra discount aur fresh quality hasil kar sakte hain.";
      }
    }

    // 4. Questions about Specific Produce Benefits
    if (q.contains('apple') || q.contains('seb')) {
      return "🍎 **Fresh Apple ke Fayde:**\n• **Antioxidants & Vitamin C:** Immunity mazboot karta hai aur infections se bachata hai.\n• **Dietary Fiber:** Hazma (digestion) aur dil ki sehat ke liye mufeed hai.\n• **Pure & Natural:** Baghair chemical wax ke direct baghat se harvested!";
    }

    if (q.contains('milk') || q.contains('doodh')) {
      return "🥛 **Organic Fresh Milk ke Fayde:**\n• **Calcium & Protein Powerhouse:** Haddiyon aur pathon (muscles) ko mazboot banata hai.\n• **Pure Organic:** Koi milawat ya harmful preservatives nahi, 100% pure subah ka fresh milk!";
    }

    if (q.contains('honey') || q.contains('shehad')) {
      return "🍯 **Pure Raw Honey ke Fayde:**\n• **Natural Antibacterial:** Gale ki kharash, khansi aur immune system ke liye behtareen.\n• **Energy Booster:** Refined sugar ka sabse sehat-mand natural mutabadil!";
    }

    if (q.contains('tomato') || q.contains('tamatar')) {
      return "🍅 **Fresh Tomatoes ke Fayde:**\n• **Lycopene Rich:** Dil ki sehat aur jild (skin) ki chamak ke liye intehai mufeed.\n• **Vitamins A & C:** Blood pressure normalize aur eyesight tez karne mein madad deta hai.";
    }

    if (q.contains('wheat') || q.contains('atta') || q.contains('grain') || q.contains('gandum')) {
      return "🌾 **Organic Whole Wheat ke Fayde:**\n• **Fiber & Complex Carbs:** Din bhar continuous energy deta hai aur weight management mein madadgar hai.";
    }

    if (q.contains('benefit') || q.contains('faida') || q.contains('faiday') || q.contains('nutrition') || q.contains('health')) {
      return "🌿 **HarvestHub Fresh Produce ke Bemisal Fayde:**\n1. **Farm to Table:** Harvest hone ke chand ghanton mein aap tak pohanchta hai jis se 100% vitamins barqarar rehte hain.\n2. **Chemical-Free:** Baghair artificial chemicals aur wax ke qudrati tor par ugaya gaya.\n3. **Immunity & Vitality:** Har product aapki aur aapki family ki sehat ko boost karti hai!";
    }

    // 5. Questions about Pickup Slots / Ordering / Delivery
    if (q.contains('pickup') || q.contains('slot') || q.contains('delivery') || q.contains('order')) {
      return "📦 **Ordering & Pickup Slots Guide:**\n• **Home Delivery:** Cart mein produce add karein aur checkout par apna address enter karein.\n• **Pickup Slots:** Delivery fee bachane ke liye checkout par 'Pickup Slot' select karein aur farmer ke farm ya local market se direct order collect karein.\n• Farmers dashboard se asaani se naye pickup time slots create kar sakte hain!";
    }

    // 6. Questions about Following Farmers
    if (q.contains('follow')) {
      return "👨‍🌾 **Farmer Following Feature:**\n• Product Detail ya Farmer Profile page par 'Follow Farmer' tap karein.\n• Is se aapko farmer ki nayi harvest, stock update aur seasonal discounts ke alerts sabse pehle milenge!";
    }

    // 7. Questions about Language / Urdu
    if (q.contains('language') || q.contains('urdu') || q.contains('zaban')) {
      return "🌐 **Bilingual Support:**\n• HarvestHub mukammal tor par Urdu aur English dono zabano mein dastiyab hai.\n• Top right par Language icon par tap karke aap aik click mein language tabdeel kar sakte hain!";
    }

    // 8. Questions about Customers / Community
    if (q.contains('customer') || q.contains('user') || q.contains('login') || q.contains('account')) {
      return "👥 **HarvestHub Community:**\n• Customers direct local farmers se rabta karke fresh organic produce mangwate hain.\n• Google Sign-in, OTP Password Reset, Live Chat aur Customer Reviews ke features mukammal active hain!";
    }

    // General fallback answer
    return "Assalam-o-Alaikum! Main HarvestAI hoon — aapka personal HarvestHub assistant 🌿\n\nMain aapki in cheezon mein madad kar sakta hoon:\n• **Farmers ($totalFarmers) & Products ($totalProducts)** ki details\n• **Saste rates & Price comparison**\n• **Health & Nutritional Benefits** (Apples, Milk, Honey, etc.)\n• **Pickup Slots & Order Placement ka tareeqa**\n\nAap mujhse app ke baare mein koi bhi sawal pooch sakte hain!";
  }

  Future<String> _callGeminiForHarvestAI() async {
    final recentMessages = aiMessages.length > 20
        ? aiMessages.sublist(aiMessages.length - 20)
        : aiMessages;

    final contents = recentMessages
        .where((m) => m.text.trim().isNotEmpty)
        .map(
          (m) => {
            'role': m.isUser ? 'user' : 'model',
            'parts': [
              {'text': m.text},
            ],
          },
        )
        .toList();

    final promptWithLiveContext = '$_harvestAISystemPrompt\n\n${_buildHarvestAIDynamicContext()}';

    final body = jsonEncode({
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': promptWithLiveContext},
        ],
      },
      'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 512},
    });

    final response = await http
        .post(
          Uri.parse(_geminiEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gemini API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Empty response from Gemini');
    }

    final parts = candidates[0]['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('No content in Gemini response');
    }

    return (parts[0]['text'] as String).trim();
  }

  Future<void> addProduct(ProductModel p) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(p.id)
        .set(_productMap(p));
    products.insert(0, p);
    notifyListeners();
  }

  Future<void> updateProduct(ProductModel p) async {
    // Get old product to check if stock changed
    final idx = products.indexWhere((x) => x.id == p.id);
    final oldStock = idx != -1 ? products[idx].stock : 0;
    final wasOutOfStock = oldStock <= 0;
    final nowInStock = p.stock > 0;
    final wasNotLowStock = oldStock >= 10;
    final nowLowStock = p.stock > 0 && p.stock < 10;

    await FirebaseFirestore.instance
        .collection('products')
        .doc(p.id)
        .set(_productMap(p), SetOptions(merge: true));

    if (idx != -1) {
      products[idx] = p;
      notifyListeners();
    }

    // Send restock notifications if product was out of stock and now is in stock
    if (wasOutOfStock && nowInStock) {
      await _sendRestockNotifications(p);
    }

    // Send low stock alert to farmer if stock drops below 10
    if (wasNotLowStock && nowLowStock) {
      await _sendLowStockAlert(p);
    }
  }

  // Send restock notifications to followers and wishlist users
  Future<void> _sendRestockNotifications(ProductModel product) async {
    try {
      final notificationService = NotificationService();

      // 1. Notify followers of this farmer
      final followersSnapshot = await FirebaseFirestore.instance
          .collection('followed_farmers')
          .where('farmerId', isEqualTo: product.farmerId)
          .get();

      for (var doc in followersSnapshot.docs) {
        final userId = doc.data()['userId'] as String;
        await notificationService.sendRestockNotification(
          userId: userId,
          productName: product.name,
          farmerId: product.farmerId,
        );
      }

      // 2. Notify users who have this product in wishlist
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      for (var userDoc in usersSnapshot.docs) {
        final wishlistDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('wishlist')
            .doc('current')
            .get();

        if (wishlistDoc.exists) {
          final wishlistData = wishlistDoc.data();
          final productIds = wishlistData?['productIds'] as List?;

          if (productIds != null && productIds.contains(product.id)) {
            await notificationService.sendWishlistAvailableNotification(
              userId: userDoc.id,
              productName: product.name,
            );
          }
        }
      }

      debugPrint(' Sent restock notifications for ${product.name}');
    } catch (e) {
      debugPrint(' Error sending restock notifications: $e');
    }
  }

  // Send low stock alert to farmer
  Future<void> _sendLowStockAlert(ProductModel product) async {
    try {
      final notificationService = NotificationService();
      await notificationService.sendLowStockAlert(
        farmerId: product.farmerId,
        productName: product.name,
        currentStock: product.stock.toInt(),
      );
      debugPrint(' Sent low stock alert for ${product.name}');
    } catch (e) {
      debugPrint(' Error sending low stock alert: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    await FirebaseFirestore.instance.collection('products').doc(id).delete();
    products.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  Map<String, dynamic> _productMap(ProductModel product) {
    return {
      'title': product.title,
      'category': product.category,
      'price': product.price,
      'unit': product.unit,
      'imageUrl': product.imageUrl,
      'stock': product.stock,
      'farmerId': product.farmerId,
      'farmerName': product.farmerName,
      'farmerPhone': product.farmerPhone,
      'farmerFarm': product.farmerFarm,
      'rating': product.rating,
      'distanceKm': product.distanceKm,
      'marketName': product.marketName,
      'description': product.description,
      'isOrganic': product.isOrganic,
      'freshnessScore': product.freshnessScore,
      'priceInsight': product.priceInsight,
      'reviewsCount': product.reviewsCount,
      'harvestDate': product.harvestDate == null
          ? null
          : Timestamp.fromDate(product.harvestDate!),
    };
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final idx = orders.indexWhere((x) => x.id == orderId);
    if (idx == -1) return;

    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final order = orders[idx];
    orders[idx] = OrderModel(
      id: order.id,
      items: order.items,
      totalAmount: order.totalAmount,
      deliveryAddress: order.deliveryAddress,
      pickupSlot: order.pickupSlot,
      paymentMethod: order.paymentMethod,
      status: newStatus,
      orderDate: order.orderDate,
      farmerName: order.farmerName,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      farmerId: order.farmerId,
      farmerPhone: order.farmerPhone,
    );

    // Send push notification to customer about status update
    try {
      // Get customer ID from order
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      final customerId = orderDoc.data()?['customerId'] as String?;

      if (customerId != null) {
        final notificationService = NotificationService();
        await notificationService.sendOrderStatusNotification(
          userId: customerId,
          orderId: orderId,
          status: newStatus,
        );
      }

      // ── Gamification hooks on delivery ───────────────────────────────────
      if (newStatus == 'Delivered' || newStatus == 'Completed') {
        final orderData = orderDoc.data();
        final gCustomerId = orderData?['customerId'] as String?;
        final gFarmerId   = orderData?['farmerId']   as String?;
        final gTotal      = (orderData?['totalAmount'] as num?)?.toDouble() ?? 0.0;

        final gs = GamificationService();

        // Award customer loyalty points
        if (gCustomerId != null) {
          await gs.awardCustomerOrderPoints(
            customerId: gCustomerId,
            orderId: orderId,
            orderTotal: gTotal,
          );
        }

        // Award farmer performance points (isOnTime = true by default here;
        // a richer implementation could compare slot time vs actual delivery time)
        if (gFarmerId != null) {
          await gs.awardFarmerOrderPoints(
            farmerId: gFarmerId,
            orderId: orderId,
            isOnTime: true,
          );
        }
      }

      // Deduct farmer points on cancellation
      if (newStatus == 'Cancelled') {
        final orderData = orderDoc.data();
        final gFarmerId = orderData?['farmerId'] as String?;
        if (gFarmerId != null) {
          await GamificationService().deductFarmerPoints(
            farmerId: gFarmerId,
            isCancellation: true,
            relatedId: orderId,
          );
        }
      }
      // ── end gamification ─────────────────────────────────────────────────
    } catch (e) {
      debugPrint('Error sending status notification: $e');
    }

    notifyListeners();
  }

  // ==================== PICKUP SLOT MANAGEMENT ====================

  // Load pickup slots for a specific farmer
  Future<void> loadPickupSlotsForFarmer(String farmerId) async {
    List<PickupSlotModel> loaded = [];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pickup_slots')
          .where('farmerId', isEqualTo: farmerId)
          .where('isActive', isEqualTo: true)
          .orderBy('date')
          .get();

      loaded = snapshot.docs
          .map((doc) => PickupSlotModel.fromMap(doc.id, doc.data()))
          .where(
            (slot) => slot.date.isAfter(
              DateTime.now().subtract(const Duration(days: 1)),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint(' Firestore pickup slots read note: $e');
    }

    // Load from local storage cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('harvesthub_farmer_pickup_slots_$farmerId');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final List list = jsonDecode(cachedStr);
        final cachedSlots = list.map((item) => PickupSlotModel.fromMap((item as Map<String, dynamic>)['id'] ?? '', item)).toList();
        for (final cs in cachedSlots) {
          if (!loaded.any((s) => s.id == cs.id || (s.dateString == cs.dateString && s.timeRange == cs.timeRange))) {
            loaded.add(cs);
          }
        }
      }
    } catch (_) {}

    pickupSlots = loaded;
    notifyListeners();
    debugPrint(' Loaded ${pickupSlots.length} pickup slots for farmer $farmerId');
  }

  // Load all available pickup slots (for customers)
  Future<void> loadAllActivePickupSlots() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pickup_slots')
          .where('isActive', isEqualTo: true)
          .orderBy('date')
          .get();

      pickupSlots = snapshot.docs
          .map((doc) => PickupSlotModel.fromMap(doc.id, doc.data()))
          .where(
            (slot) =>
                slot.date.isAfter(
                  DateTime.now().subtract(const Duration(days: 1)),
                ) &&
                !slot.isFull,
          )
          .toList();

      notifyListeners();
      debugPrint(' Loaded ${pickupSlots.length} available pickup slots');
    } catch (e) {
      debugPrint(' Error loading pickup slots: $e');
    }
  }

  // Get available pickup slots for a specific farmer
  List<PickupSlotModel> getPickupSlotsForFarmer(String farmerId) {
    return pickupSlots
        .where(
          (slot) =>
              slot.farmerId == farmerId &&
              !slot.isFull &&
              slot.date.isAfter(
                DateTime.now().subtract(const Duration(days: 1)),
              ),
        )
        .toList();
  }

  // Create a new pickup slot (Farmer)
  Future<void> createPickupSlot(PickupSlotModel slot) async {
    String slotId = 'slot_${DateTime.now().millisecondsSinceEpoch}';
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('pickup_slots')
          .add(slot.toMap());
      slotId = docRef.id;
    } catch (e) {
      debugPrint(' Firestore pickup slot write notice: $e');
    }

    final newSlot = slot.copyWith(id: slotId);
    pickupSlots.insert(0, newSlot);

    // Save to local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final slotsJson = jsonEncode(pickupSlots.map((s) => s.toMap()).toList());
      await prefs.setString('harvesthub_farmer_pickup_slots_${slot.farmerId}', slotsJson);
    } catch (_) {}

    notifyListeners();
    debugPrint(' Created pickup slot: ${slot.dateString} ${slot.timeRange}');
  }

  // Update pickup slot (Farmer)
  Future<void> updatePickupSlot(PickupSlotModel slot) async {
    try {
      await FirebaseFirestore.instance
          .collection('pickup_slots')
          .doc(slot.id)
          .update(slot.toMap());
    } catch (_) {}

    final idx = pickupSlots.indexWhere((s) => s.id == slot.id);
    if (idx != -1) {
      pickupSlots[idx] = slot;
      try {
        final prefs = await SharedPreferences.getInstance();
        final slotsJson = jsonEncode(pickupSlots.map((s) => s.toMap()).toList());
        await prefs.setString('harvesthub_farmer_pickup_slots_${slot.farmerId}', slotsJson);
      } catch (_) {}
      notifyListeners();
    }
    debugPrint(' Updated pickup slot: ${slot.dateString} ${slot.timeRange}');
  }

  // Delete pickup slot (Farmer)
  Future<void> deletePickupSlot(String slotId) async {
    try {
      await FirebaseFirestore.instance
          .collection('pickup_slots')
          .doc(slotId)
          .delete();
    } catch (_) {}

    pickupSlots.removeWhere((s) => s.id == slotId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final farmerId = FirebaseAuth.instance.currentUser?.uid;
      if (farmerId != null) {
        final slotsJson = jsonEncode(pickupSlots.map((s) => s.toMap()).toList());
        await prefs.setString('harvesthub_farmer_pickup_slots_$farmerId', slotsJson);
      }
    } catch (_) {}

    notifyListeners();
    debugPrint(' Deleted pickup slot');
  }

  // Book a pickup slot (increment booked count)
  Future<void> bookPickupSlot(String slotId) async {
    try {
      await FirebaseFirestore.instance
          .collection('pickup_slots')
          .doc(slotId)
          .update({'bookedSlots': FieldValue.increment(1)});

      final idx = pickupSlots.indexWhere((s) => s.id == slotId);
      if (idx != -1) {
        pickupSlots[idx] = pickupSlots[idx].copyWith(
          bookedSlots: pickupSlots[idx].bookedSlots + 1,
        );
        notifyListeners();
      }

      debugPrint(' Booked pickup slot');
    } catch (e) {
      debugPrint(' Error booking pickup slot: $e');
      rethrow;
    }
  }

  // Cancel booking (decrement booked count)
  Future<void> cancelPickupSlotBooking(String slotId) async {
    try {
      await FirebaseFirestore.instance
          .collection('pickup_slots')
          .doc(slotId)
          .update({'bookedSlots': FieldValue.increment(-1)});

      final idx = pickupSlots.indexWhere((s) => s.id == slotId);
      if (idx != -1) {
        pickupSlots[idx] = pickupSlots[idx].copyWith(
          bookedSlots: pickupSlots[idx].bookedSlots - 1,
        );
        notifyListeners();
      }

      debugPrint(' Cancelled pickup slot booking');
    } catch (e) {
      debugPrint(' Error cancelling pickup slot booking: $e');
      rethrow;
    }
  }

  // Toggle slot active status
  Future<void> togglePickupSlotStatus(String slotId) async {
    try {
      final idx = pickupSlots.indexWhere((s) => s.id == slotId);
      if (idx == -1) return;

      final newStatus = !pickupSlots[idx].isActive;

      await FirebaseFirestore.instance
          .collection('pickup_slots')
          .doc(slotId)
          .update({'isActive': newStatus});

      pickupSlots[idx] = pickupSlots[idx].copyWith(isActive: newStatus);
      notifyListeners();

      debugPrint(' Toggled pickup slot status to $newStatus');
    } catch (e) {
      debugPrint(' Error toggling pickup slot status: $e');
      rethrow;
    }
  }
}
