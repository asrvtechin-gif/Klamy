import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const _channel = AndroidNotificationChannel(
    'klamy_claim_updates',
    'Klamy claim updates',
    description: 'Claim, document, and account updates from Klamy.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  Future<void> initialize({required ValueChanged<String?> onNotificationTap}) {
    return _initialization ??= _initialize(
      onNotificationTap: onNotificationTap,
    );
  }

  Future<void> _initialize({
    required ValueChanged<String?> onNotificationTap,
  }) async {
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_klamy'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        web: WebInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap(response.payload);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Foreground FCM messages are shown through the local notification plugin.
    if (!kIsWeb) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
    }

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      onNotificationTap(launchDetails?.notificationResponse?.payload);
    }
  }

  Future<void> showForegroundMessage({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: const AndroidNotificationDetails(
          'klamy_claim_updates',
          'Klamy claim updates',
          channelDescription:
              'Claim, document, and account updates from Klamy.',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_klamy',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        web: WebNotificationDetails(
          iconUrl: Uri.base.resolve('icons/Icon-192.png'),
          badgeUrl: Uri.base.resolve('icons/Icon-192.png'),
        ),
      ),
      payload: payload,
    );
  }
}
