import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  // Initialize FCM and local notifications
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('[NotificationService] Push notification permission granted');
      } else {
        debugPrint('[NotificationService] Push notification permission denied');
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Get FCM token
      _fcmToken = await _fcm.getToken();
      debugPrint('[NotificationService] FCM Token: $_fcmToken');

      // Save token to Firestore
      if (_fcmToken != null) {
        await _saveFCMToken(_fcmToken!);
      }

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveFCMToken(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      debugPrint('[NotificationService] Initialized');
    } catch (e) {
      debugPrint('[NotificationService] Error initializing notifications: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'harvesthub_channel',
        'HarvestHub Notifications',
        description: 'Notifications for orders, restocks, and updates',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('[NotificationService] FCM token saved to Firestore');
      }
    } catch (e) {
      debugPrint('[NotificationService] Error saving FCM token: $e');
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[NotificationService] Foreground message: ${message.messageId}');
    
    final notification = message.notification;
    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'HarvestHub',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'harvesthub_channel',
      'HarvestHub Notifications',
      channelDescription: 'Notifications for orders, restocks, and updates',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Handle notification tap (from background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[NotificationService] Notification tapped: ${message.data}');
    // Navigate based on notification data
    // This will be handled in main.dart with NavigatorKey
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Local notification tapped: ${response.payload}');
    // Handle navigation
  }

  // Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final type = data?['type'] as String? ?? 'system';
      
      // Save notification to Firestore (for farmer and customer alerts feed)
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'isRead': false,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[NotificationService] Notification saved to Firestore for user: $userId');

      // Also show local push banner if active
      await _showLocalNotification(title: title, body: body);

      // Check user's FCM token for external push
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'] as String?;
      if (fcmToken == null) {
        debugPrint('[NotificationService] FCM token pending for user: $userId (In-app alert stored)');
      }
    } catch (e) {
      debugPrint('[NotificationService] Error sending notification: $e');
    }
  }

  // Notification types for different scenarios

  // Order status update notification
  Future<void> sendOrderStatusNotification({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    String title = 'Order Update';
    String body = 'Your order #${orderId.substring(orderId.length - 6).toUpperCase()} is now $status';

    if (status.toLowerCase() == 'processing') {
      body = 'Your order is being processed by the farmer';
    } else if (status.toLowerCase() == 'ready for pickup') {
      body = 'Your order is ready for pickup!';
    } else if (status.toLowerCase() == 'in transit') {
      body = 'Your order is on the way!';
    } else if (status.toLowerCase() == 'delivered') {
      title = 'Order Delivered!';
      body = 'Your order has been delivered. Enjoy fresh products!';
    }

    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      data: {'type': 'order_update', 'orderId': orderId, 'status': status},
    );
  }

  // New order notification for farmer
  Future<void> sendNewOrderNotification({
    required String farmerId,
    required String orderId,
    required String customerName,
    required double totalAmount,
  }) async {
    await sendNotificationToUser(
      userId: farmerId,
      title: 'New Order Received!',
      body: 'New order from $customerName - Rs. ${totalAmount.toStringAsFixed(0)}',
      data: {'type': 'new_order', 'orderId': orderId},
    );
  }

  // Restock alert notification
  Future<void> sendRestockNotification({
    required String userId,
    required String productName,
    required String farmerId,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Product Restocked!',
      body: '$productName is now back in stock!',
      data: {'type': 'restock', 'productName': productName, 'farmerId': farmerId},
    );
  }

  // Low stock alert for farmer
  Future<void> sendLowStockAlert({
    required String farmerId,
    required String productName,
    required int currentStock,
  }) async {
    await sendNotificationToUser(
      userId: farmerId,
      title: 'Low Stock Alert',
      body: '$productName is running low (Only $currentStock left)',
      data: {'type': 'low_stock', 'productName': productName},
    );
  }

  // Wishlist item available notification
  Future<void> sendWishlistAvailableNotification({
    required String userId,
    required String productName,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Wishlist Item Available!',
      body: '$productName from your wishlist is now available',
      data: {'type': 'wishlist_available', 'productName': productName},
    );
  }

  // Followed farmer new product notification
  Future<void> sendFollowedFarmerNewProductNotification({
    required String userId,
    required String farmerName,
    required String productName,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'New Product from $farmerName',
      body: '$farmerName has added $productName',
      data: {'type': 'farmer_new_product', 'farmerName': farmerName},
    );
  }

  // Get current FCM token
  String? get fcmToken => _fcmToken;

  // Dispose
  void dispose() {
    // Cleanup if needed
  }
}
