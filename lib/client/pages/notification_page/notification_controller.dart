import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/claim_repository.dart';
import '../../../services/push_notification_service.dart';
import 'notification_page.dart';

class NotificationController extends GetxController {
  static const _webVapidKey = String.fromEnvironment(
    'FIREBASE_MESSAGING_WEB_VAPID_KEY',
  );
  final categories = const <String>[
    'All',
    'Unread',
    'Claims',
    'Reminders',
    'System',
  ];

  final RxString selectedFilter = 'All'.obs;
  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  late final ClaimRepository _repository;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationsSubscription;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  String? _registeredFcmToken;
  String? _registeredFcmUid;

  @override
  void onInit() {
    super.onInit();
    _repository = Get.isRegistered<ClaimRepository>()
        ? Get.find<ClaimRepository>()
        : Get.put(ClaimRepository(), permanent: true);
    _notificationsSubscription = _repository.watchNotifications().listen(
      notifications.assignAll,
      onError: (Object error) => Get.snackbar(
        'Notifications unavailable',
        'Could not load notifications: $error',
      ),
    );
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _registerCurrentDevice,
    );
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      _saveFcmToken,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializePushNotifications());
    });
  }

  Future<void> _initializePushNotifications() async {
    try {
      await PushNotificationService.instance.initialize(
        onNotificationTap: (payload) =>
            unawaited(_handleLocalNotificationTap(payload)),
      );
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        (message) => unawaited(_handleForegroundMessage(message)),
      );
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => unawaited(_handleRemoteNotificationTap(message)),
      );

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        unawaited(_handleRemoteNotificationTap(initialMessage));
      }
    } catch (error) {
      debugPrint('Klamy push notification setup failed: $error');
    }
  }

  Future<void> _registerCurrentDevice(User? user) async {
    if (user == null) return;
    await _saveFcmTokenForUser(user.uid);
  }

  Future<void> _saveFcmToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      if (_registeredFcmUid == user.uid &&
          _registeredFcmToken != null &&
          _registeredFcmToken != token) {
        await _repository.removeFcmToken(_registeredFcmToken!);
      }
      await _repository.saveFcmToken(token);
      _registeredFcmToken = token;
      _registeredFcmUid = user.uid;
    } catch (error) {
      debugPrint('Could not save the Klamy FCM token: $error');
    }
  }

  Future<void> _saveFcmTokenForUser(String uid) async {
    try {
      final token = kIsWeb
          ? (_webVapidKey.isEmpty
                ? null
                : await FirebaseMessaging.instance.getToken(
                    vapidKey: _webVapidKey,
                  ))
          : await FirebaseMessaging.instance.getToken();
      if (token != null && FirebaseAuth.instance.currentUser?.uid == uid) {
        if (_registeredFcmUid == uid &&
            _registeredFcmToken != null &&
            _registeredFcmToken != token) {
          await _repository.removeFcmToken(_registeredFcmToken!);
        }
        await _repository.saveFcmToken(token);
        _registeredFcmToken = token;
        _registeredFcmUid = uid;
      }
    } catch (error) {
      debugPrint('Could not register the Klamy FCM token: $error');
    }
  }

  Future<bool> requestNotificationsPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (granted) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) await _saveFcmTokenForUser(user.uid);
      }
      return granted;
    } catch (error) {
      debugPrint('Could not request Klamy notification permission: $error');
      return false;
    }
  }

  Future<void> unregisterCurrentDevice() async {
    if (_registeredFcmUid != null &&
        _registeredFcmUid != FirebaseAuth.instance.currentUser?.uid) {
      return;
    }
    try {
      final token =
          _registeredFcmToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _repository.removeFcmToken(token);
      _registeredFcmToken = null;
      _registeredFcmUid = null;
    } catch (error) {
      debugPrint('Could not unregister the Klamy FCM token: $error');
    }
  }

  Future<Map<String, dynamic>> _recordForMessage(RemoteMessage message) async {
    final data = message.data;
    final requestedCategory = (data['category'] ?? '').toString();
    const validCategories = {'Claims', 'Reminders', 'System'};
    final category = validCategories.contains(requestedCategory)
        ? requestedCategory
        : 'System';
    final actionTab = int.tryParse((data['actionTab'] ?? '').toString());
    final notification = <String, dynamic>{
      'title': (message.notification?.title ?? data['title'] ?? 'Klamy update')
          .toString(),
      'body': (message.notification?.body ?? data['body'] ?? '').toString(),
      'category': category,
      'messageId': message.messageId ?? '',
      if (actionTab != null && actionTab >= 0 && actionTab <= 4)
        'actionTab': actionTab,
    };
    final id = await _repository.saveNotification(notification);
    notification
      ..['id'] = id
      ..['isRead'] = false
      ..['createdAt'] = DateTime.now().millisecondsSinceEpoch;
    return notification;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final notification = await _recordForMessage(message);
      await PushNotificationService.instance.showForegroundMessage(
        id: message.messageId.hashCode & 0x7fffffff,
        title: notification['title'].toString(),
        body: notification['body'].toString(),
        payload: jsonEncode({'id': notification['id']}),
      );
    } catch (error) {
      debugPrint('Could not display a Klamy notification: $error');
    }
  }

  Future<void> _handleRemoteNotificationTap(RemoteMessage message) async {
    try {
      final notification = await _recordForMessage(message);
      _openNotificationPage(notification['id'].toString());
    } catch (error) {
      debugPrint('Could not open the Klamy notification: $error');
      _openNotificationPage(null);
    }
  }

  Future<void> _handleLocalNotificationTap(String? payload) async {
    String? id;
    if (payload != null && payload.isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) id = decoded['id']?.toString();
      } on FormatException {
        id = null;
      }
    }
    if (id != null && id.isNotEmpty) {
      try {
        await markAsRead(id);
      } catch (error) {
        debugPrint('Could not mark the opened notification as read: $error');
      }
    }
    _openNotificationPage(id);
  }

  void _openNotificationPage(String? notificationId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute.contains('NotificationPage')) return;
      Get.to(() => NotificationPage(), arguments: notificationId);
    });
  }

  int get unreadCount =>
      notifications.where((item) => item['isRead'] != true).length;

  List<Map<String, dynamic>> get filteredNotifications {
    final filter = selectedFilter.value;
    if (filter == 'Unread') {
      return notifications.where((item) => item['isRead'] != true).toList();
    }
    if (filter == 'All') return notifications.toList();
    return notifications.where((item) => item['category'] == filter).toList();
  }

  void setFilter(String category) => selectedFilter.value = category;

  Future<void> markAsRead(String id) async {
    await _repository.markNotificationRead(id);
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllNotificationsRead();
      Get.snackbar(
        'Notifications Updated',
        'All notifications marked as read.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F766E),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    } catch (error) {
      Get.snackbar('Could not update notifications', error.toString());
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
      Get.snackbar(
        'Deleted',
        'Notification removed.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar('Could not delete notification', error.toString());
    }
  }

  Future<void> clearAll() async {
    try {
      await _repository.clearNotifications();
      Get.snackbar(
        'Cleared All',
        'All notifications cleared.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar('Could not clear notifications', error.toString());
    }
  }

  @override
  void onClose() {
    _notificationsSubscription?.cancel();
    _authSubscription?.cancel();
    _tokenSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
    super.onClose();
  }
}
